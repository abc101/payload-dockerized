#!/bin/bash

# Color definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- STEP 0: Pre-flight Check ---
echo -e "${BLUE}Checking for required configuration files...${NC}"
REQUIRED_FILES=(".env" "Dockerfile" "docker-compose.yml")
MISSING_FILES=()

for file in "${REQUIRED_FILES[@]}"; do
    [ ! -f "$file" ] && MISSING_FILES+=("$file")
done

if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo -e "${RED}Error: Missing required file(s): ${MISSING_FILES[*]}${NC}"
    exit 1
fi

# --- STEP 1: Load .env Variables ---
export $(grep -v '^#' .env | xargs)
if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}Error: DATABASE_URL is missing in .env${NC}"
    exit 1
fi

# --- STEP 2: Interactive Safe Shutdown (Default: N) ---
if [ "$(docker compose ps --services --filter "status=running")" ]; then
    echo -e "${YELLOW}Warning: Moduboard containers are already running.${NC}"
    # Default is set to No [y/N]
    read -p "Do you want to stop them and proceed with setup? (y/N): " stop_confirm
    
    # Only proceed if the user explicitly types y or yes
    if [[ "$stop_confirm" =~ ^[yY]([eE][sS])?$ ]]; then
        echo -e "${BLUE}Stopping containers...${NC}"
        docker compose down
    else
        echo -e "${YELLOW}Setup aborted to keep existing containers running.${NC}"
        exit 0
    fi
fi

# --- STEP 3: Interactive Directory Management (Default: 1) ---
SHOULD_CREATE_PAYLOAD=false

if [ -d "html" ] && [ "$(ls -A html)" ]; then
    echo -e "${YELLOW}Notice: 'html' directory already exists and is not empty.${NC}"
    echo -e "How would you like to proceed?"
    echo -e "  1) ${GREEN}Use existing source${NC} (Keep current files in 'html') [Default]"
    echo -e "  2) ${RED}Fresh Install${NC} (Delete everything in 'html' and start over)"
    
    read -p "Select option (1/2): " choice
    choice=${choice:-1} 

    case $choice in
        1)
            # Check .env exists in html
            if [ ! -f "html/.env" ]; then
                echo -e "${RED}Error: Environment file (.env) is missing inside './html'.${NC}"
                echo -e "${RED}Please place the required .env file in './html' or choose 'Fresh Install'.${NC}"
                exit 1
            fi
            
            echo -e "${BLUE}Proceeding with existing source code...${NC}"
            SHOULD_CREATE_PAYLOAD=false
            ;;
        2)
            echo -e "${RED}Deleting everything in 'html' and starting fresh...${NC}"
            rm -rf html
            mkdir html
            SHOULD_CREATE_PAYLOAD=true
            ;;
        *)
            echo -e "${RED}Invalid selection. Exiting.${NC}"
            exit 1
            ;;
    esac
else
    echo -e "${BLUE}Creating 'html' directory and starting fresh install...${NC}"
    mkdir -p html
    SHOULD_CREATE_PAYLOAD=true
fi

# --- STEP 4: Docker Build & Up ---
echo -e "${BLUE}[1/5] Building and starting containers...${NC}"
docker compose up -d --build

echo -e "${BLUE}Waiting for Database to be ready...${NC}"
until docker compose exec db pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} > /dev/null 2>&1; do
    echo -ne "."
    sleep 1
done
echo -e "${GREEN} DB Ready!${NC}"

# --- STEP 5: Payload Setup (Create or Install) ---
if [ "$SHOULD_CREATE_PAYLOAD" = true ]; then
    echo -e "${BLUE}[2/5] Scaffolding NEW Payload app...${NC}"
    CREATE_CMD="pnpm create payload-app@latest . \
      --template blank \
      --db postgres \
      --db-connection-string $DATABASE_URL \
      --no-agent \
      --no-git"
    
    if docker compose exec app $CREATE_CMD; then
        echo -e "${GREEN}✔ Payload installation successful!${NC}"
    else
        echo -e "${RED}❌ Installation failed.${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}[2/5] Installing dependencies for existing project...${NC}"
    if docker compose exec app pnpm install; then
        echo -e "${GREEN}✔ Dependencies installed successfully!${NC}"
    else
        echo -e "${RED}❌ pnpm install failed.${NC}"
        exit 1
    fi
fi

# --- STEP 6: Restart App for Clean Start ---
echo -e "${BLUE}[3/5] Restarting app container to apply changes...${NC}"
docker compose restart app

# --- STEP 7: Wait for Server Ready ---
echo -e "${BLUE}[4/5] Waiting for dev server to be ready...${NC}"

# Monitor logs for "Ready in" or "started server on" to confirm server is up
docker compose logs -f app | while read line; do
    echo "$line"
    if [[ "$line" == *"Ready in"* || "$line" == *"started server on"* ]]; then
        echo -e "\n${GREEN}✔ Server is ready!${NC}"
        echo -e "${BLUE}[5/5] Setup complete!${NC}"
        echo -e "Admin Dashboard: http://localhost:3000/admin"
        echo -e "Local API: http://localhost:3000/api"
        # Stop monitoring logs once server is ready
        pkill -P $$ 
        break
    fi
done
#!/bin/bash

# Builds a full release of a mod, compiling scripts, packing resources into a
# BSA and bundling the whole thing in a 7z archive.

# Color constants
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_BLUE='\033[1;34m'
C_YELLOW='\033[1;33m'
C_NC='\033[0m'

# Variable definitions relating to your Skyrim installation
# These will probably have to be changed to fit your paths.
# ----------------------------------------------------------
# The path to the Skyrim / Skyrim SE installation to use
SKYRIM_PATH="G:/steam/steamapps/common/Skyrim Special Edition"
# The path to the vanilla Skyrim, SKSE and SkyUI sources.
SKYRIM_SOURCES="${SKYRIM_PATH}/Data/Scripts/Source"
# The path to the papyrus compiler.
COMPILER="${SKYRIM_PATH}/Papyrus Compiler/PapyrusCompiler.exe"
# The path to the flags file for Skyrim.
FLAGS="${SKYRIM_SOURCES}/TESV_Papyrus_Flags.flg"

# Variable definitions relating to the actual mod being built.
# You will definitely want to change serveral of these.
# ----------------------------------------------------------
# The version to release the mod with
VERSION="VERSION_HERE"
# The name of the folder in which the mod will be built
TEMP_FOLDER="temp"
# The name to use for the esp / bsa / modgroups / ini file.
ESP_NAME="ESP_NAME_HERE"
# The name to use for logging and the release file
MOD_NAME="MOD_NAME_HERE"
# The name to use for the release file
RELEASE_NAME="${MOD_NAME} v${VERSION}.7z"

# Print a nice greeting
echo -e "Welcome to the ${C_GREEN}${MOD_NAME}${C_NC} release builder!"
echo ""

# Find out if we should build a dev or a release file
release=-1
while [[ release -eq -1 ]]; do
    echo -e "Build a (${C_RED}d${C_NC})${C_YELLOW}evelopment${C_NC} or a (${C_RED}r${C_NC})${C_YELLOW}elease${C_NC} file?"
    read -s -n 1 key
    if [[ "${key}" == "d" ]]
    then
        release=0
    elif [[ "${key}" == "r" ]]
    then
        release=1
    else
        echo -e "${C_GREEN}${key}${C_NC} is not a valid file type."
    fi
done

# Delete and recreate a temp folder to make sure we have a fresh setup
echo ""
echo -e "${C_GREEN}==>${C_NC} Creating new temporary build folder..."

rm -rf "${TEMP_FOLDER}"
mkdir -p "${TEMP_FOLDER}/Data"

# Copy anything we can find into the temp/Data folder
cp -r "grass" "${TEMP_FOLDER}/Data" 2>/dev/null # TODO Can you even change / use this folder in mods?
cp -r "lodsettings" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "interface" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "meshes" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "music" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "scripts" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "seq" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "sound" "${TEMP_FOLDER}/Data" 2>/dev/null
cp -r "strings" "${TEMP_FOLDER}/Data" 2>/dev/null # TODO Pretty sure mods can't use this folder
cp -r "shadersfx" "${TEMP_FOLDER}/Data" 2>/dev/null # TODO Pretty sure mods can't use this folder
cp -r "textures" "${TEMP_FOLDER}/Data" 2>/dev/null
cp "${ESP_NAME}".* "${TEMP_FOLDER}" 2>/dev/null

# These are only used in release mode
if [[ $release -eq 1 ]]
then
    # If they don't exist, warn the user
    if [ ! -f "BSAManifest.txt" ] || [ ! -f "BSAScript.txt" ]
    then
        echo "${C_RED}Error: BSAManifest.txt and / or BSAScript.txt missing - cannot create a release file.${C_NC}"
        exit 1
    fi

    cp "BSAManifest.txt" "${TEMP_FOLDER}"
    cp "BSAScript.txt" "${TEMP_FOLDER}"
fi

# Move into the temp folder to make the rest of this procedure simpler
cd "${TEMP_FOLDER}"

# Compile all scripts, adding the appropriate flags for each mode
echo ""
echo -e "${C_GREEN}==>${C_NC} Compiling scripts, this may take a while..."

if [[ $release -eq 0 ]]
then
    "${COMPILER}" "Data/scripts/source" -a -q -o="Data/scripts" -i="Data/scripts/source;${SKYRIM_SOURCES}" -f="${FLAGS}"
else
    "${COMPILER}" "Data/scripts/source" -a -q -op -o="Data/scripts" -i="Data/scripts/source;${SKYRIM_SOURCES}" -f="${FLAGS}"
fi

# If we're in development mode, use loose files
# In release mode, use a BSA
echo ""
echo -e "${C_GREEN}==>${C_NC} Packing files into an archive..."
if [[ $release -eq 0 ]]
then
    cd "Data"
    7z a "../${RELEASE_NAME}" "../${ESP_NAME}".* "*"
else
    "${SKYRIM_PATH}/Tools/Archive/Archive.exe" "BSAScript.txt"
    rm -f "${ESP_NAME}.bsl"
    7z a "${RELEASE_NAME}" "${ESP_NAME}".*
fi

# If we were launched in interactive mode (no parameter), wait for confirmation
if [ -z $1 ]
then
    echo ""
    echo -e "${C_GREEN}==>${C_NC} File built as ${C_BLUE}${TEMP_FOLDER}/${RELEASE_NAME}${C_NC}!"
    echo "Press any key to continue"
    read -s -n 1
fi

#! /bin/bash

#Create a encrypted disk image of contents of a folder

set -e;

function pure_version() {
	echo '1.0.0'
}

function version() {
	echo "encrypted-dmg $(pure_version)"
}

function usage() {
	version
	echo ""
	echo "Create PRIVATE space for your personal files"
	echo "Usage:  $(basename $0) [create|add|chpass|help|version] <image> source_folder"
  	echo ""
  	echo "Verbs:"
  	echo "  create"
  	echo "      create a brand new disk image, if not exists, with password, or overwrite an existing disk image "
  	echo "  add"
  	echo "      add a file or directory into an existing disk image"
	echo "  chpass"
  	echo "      change the password of a disk image"
	echo "  Other verbs: help, version."
	
	exit 0
}

function create_dmg() {

	test -z "$2" && {
  		echo "Not enough arguments. Invoke with --help for help."
  		exit 1
	}

	DMG_PATH="$1"
	DMG_DIRNAME="$(dirname "$DMG_PATH")"
	DMG_DIR="$(cd $DMG_DIRNAME > /dev/null; pwd)"
	DMG_NAME="$(basename "$DMG_PATH")"
	SRC_FOLDER="$(cd "$2" > /dev/null; pwd)"
	VOLUME_NAME="$(basename "$DMG_PATH" .dmg)"

	test -d "$SRC_FOLDER" || {
		echo "Invalid path ${SRC_FOLDER}."
		exit 1
	}

	if [ -f "$SRC_FOLDER/.DS_Store" ]; then
    	echo "Deleting any .DS_Store in source folder"
    	rm "$SRC_FOLDER/.DS_Store"
	fi

	# Create the image
	echo "Creating disk image ${DMG_NAME}..."
	test -f "${DMG_DIR}/${DMG_NAME}" && rm -f "${DMG_DIR}/${DMG_NAME}"
	ACTUAL_SIZE=`du -sm "$SRC_FOLDER" | sed -e 's/	.*//g'`
	DISK_IMAGE_SIZE=$(expr $ACTUAL_SIZE + 20)
	hdiutil create -encryption -stdinpass -srcfolder "$SRC_FOLDER" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DISK_IMAGE_SIZE}m "${DMG_DIR}/${DMG_NAME}"

	echo "Disk image created"
	exit 0
}

function change_pass() {

	test -z "$1" && {
  		echo "Not enough arguments. Invoke with --help for help."
  		exit 1
	}

	DMG_PATH="$1"
	DMG_NAME="$(basename "$DMG_PATH")"

	test -f "$DMG_PATH" || {
		echo "Invalid path ${DMG_PATH}."
		exit 1
	}

	if [ "${DMG_NAME##*.}" != "dmg" ]; then
		echo "${DMG_NAME} is not a dmg file."
		exit 1
	fi

	hdiutil chpass "${DMG_PATH}"
	exit 0
}

function add_file() {

	test -z "$2" && {
  		echo "Not enough arguments. Invoke with --help for help."
  		exit 1
	}

	DMG_PATH="$1"
	DMG_DIRNAME="$(dirname "$DMG_PATH")"
	DMG_DIR="$(cd $DMG_DIRNAME > /dev/null; pwd)"
	DMG_NAME="$(basename "$DMG_PATH")"
	DMG_TEMP_NAME="$DMG_DIR/rw.${DMG_NAME}"
	VOLUME_NAME="$(basename "$DMG_PATH" .dmg)"
	FILE_PATH="$2"

	test -f "$DMG_PATH" || {
		echo "Invalid path ${DMG_PATH}."
		exit 1
	}

	test -f "$FILE_PATH" || {
		echo "Invalid file ${FILE_PATH}."
		exit 1
	}

	test -d "$FILE_PATH" || {
		echo "Invalid directory ${FILE_PATH}."
		exit 1
	}	


	if [ "${DMG_NAME##*.}" != "dmg" ]; then
		echo "${DMG_NAME} is not a dmg file."
		exit 1
	fi

	# mount it
	echo "Mounting disk image..."
	MOUNT_DIR="/Volumes/${VOLUME_NAME}"
	# try unmount dmg if it was mounted previously (e.g. user installed app and mounted dmg)
	echo "Unmounting disk image..."
	DEV_NAME=$(hdiutil info | egrep '^/dev/' | sed 1q | awk '{print $1}')
	test -d "${MOUNT_DIR}" && hdiutil detach "${DEV_NAME}"
	
	# resize
	ACTUAL_SIZE=`du -sm "$DMG_PATH" | sed -e 's/	.*//g'`
	FILE_SIZE=`du -sm "$FILE_PATH" | sed -e 's/	.*//g'`
	DISK_IMAGE_SIZE=$(expr $ACTUAL_SIZE + $FILE_SIZE)	
	hdiutil resize -size ${DISK_IMAGE_SIZE}m "${DMG_DIR}/${DMG_NAME}"
	

	echo "Mount directory: $MOUNT_DIR"
	DEV_NAME=$(hdiutil attach -readwrite -noverify -noautoopen -nobrowse "${DMG_NAME}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
	echo "Device name:     $DEV_NAME"

	if ! test -z "${FILE_PATH}"; then

		if [ -f "$FILE_PATH" ]; then
			echo "Copying file ${FILE_PATH}..."
			cp "${FILE_PATH}" "${MOUNT_DIR}"

		elif [ -d "$FILE_PATH" ]; then
			echo "Copying directory ${FILE_PATH}..."
			cp -r "${FILE_PATH}" "${MOUNT_DIR}"
		fi

	fi


	# unmount
	echo "Unmounting disk image..."
	hdiutil detach "${DEV_NAME}"
}

case $1 in
	create)
		shift;
		create_dmg $*;;
	chpass)
		shift;
		change_pass $*;;
	add)
		shift;
		add_file $*;;
	help)
		usage;;
	version)
		version;
		exit 0;;
	*)
		echo "Unknown verb $1. "
		echo ""
		echo "Need any help? Plesae enter:"
		echo "   $(basename $0) help"
		exit 1;;
esac
SRC_DIR = ..

SELECT_FILES = $(SRC_DIR)/selectFiles.rb collect_files.yaml
BUILDREV = svn_build_rev.rb
RBPACK = ../../../../ruby_sfx/build_win/rbpack
BUILD_DIR = build_dir
TARGET = miqvme.exe

TFP = $(shell pwd)/$(TARGET)

$(TARGET): FRC
	rm -f $(TARGET)
	rm -rf $(BUILD_DIR)
	cp $(RBPACK) $(TARGET)
	cd $(SRC_DIR); ruby $(BUILDREV)
	ruby $(SELECT_FILES)
	cd $(BUILD_DIR); zip -A -r $(TFP) *
	
clean:
	rm -f $(TARGET)
	rm -rf $(BUILD_DIR)

FRC:

export GOPATH=$(CURDIR)/.build

GO ?= /usr/bin/go
GOARCH ?= amd64
PACKAGE := phabricator.wikimedia.org/source/mwctl
BUILD_DIR := $(GOPATH)/src/$(PACKAGE)
BINDIR := $(CURDIR)/bin


all: linux windows darwin

clean:
	rm -rf $(CURDIR)/.build
	rm -f $(BINDIR)/mwctl-linux-$(GOARCH) $(BINDIR)/mwctl-windows-$(GOARCH) $(BINDIR)/mwctl-darwin-$(GOARCH)

setup:
	install -d $(dir $(BUILD_DIR)) $(BINDIR)
	[ -h "$(BUILD_DIR)" ] || ln -s $(CURDIR) $(BUILD_DIR)
	cd $(BUILD_DIR) && $(GO) get ./...

linux: setup
	# Linux
	cd $(BUILD_DIR) && GOOS=linux GOARCH=$(GOARCH) $(GO) build -v -x -o mwctl-linux-$(GOARCH)
	mv $(BUILD_DIR)/mwctl-linux-$(GOARCH) $(BINDIR)

windows: setup
	# Windows
	cd $(BUILD_DIR) && GOOS=windows GOARCH=$(GOARCH) $(GO) build -v -x -o mwctl-windows-$(GOARCH).exe
	mv $(BUILD_DIR)/mwctl-windows-$(GOARCH).exe $(BINDIR)

darwin: setup
	# MacOS
	cd $(BUILD_DIR) && GOOS=darwin GOARCH=$(GOARCH) $(GO) build -v -x -o mwctl-darwin-$(GOARCH)
	mv $(BUILD_DIR)/mwctl-darwin-$(GOARCH) $(BINDIR)


.PHONY: clean all

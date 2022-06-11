# File: /main.mk
# Project: mkpm-deps
# File Created: 11-06-2022 13:28:59
# Author: Clay Risser
# -----
# Last Modified: 11-06-2022 14:45:29
# Modified By: Clay Risser
# -----
# Risser Labs LLC (c) Copyright 2021 - 2022
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEPS_AUTOINSTALL ?= 0
DEPS_APK := $(DEPS_ALL) $(DEPS_APK)
DEPS_BREW := $(DEPS_ALL) $(DEPS_BREW)
DEPS_YUM := $(DEPS_ALL) $(DEPS_YUM)
DEPS_APT := $(DEPS_ALL) $(DEPS_APT) $(DEPS_APT_GET)

include $(MKPM_TMP)/deps/ready
$(MKPM_TMP)/deps/ready: $(PROJECT_ROOT)/mkpm.mk $(PROJECT_ROOT)/Makefile
ifneq (1,$(DEPS_SKIP))
ifeq ($(PKG_MANAGER),yum)
	@$(call deps_requires_pkgs,$(DEPS_YUM))
endif
ifeq ($(PKG_MANAGER),apt-get)
	@$(call deps_requires_pkgs,$(DEPS_APT))
endif
ifeq ($(PKG_MANAGER),apk)
	@$(call deps_requires_pkgs,$(DEPS_APK))
endif
ifeq ($(PKG_MANAGER),brew)
	@$(call deps_requires_pkgs,$(DEPS_BREW))
endif
endif
	@$(MKDIR) -p $(@D)
	@$(TOUCH) -m $@

define deps_requires_pkgs
pkg_manager_install() { \
	if [ "$(PKG_MANAGER)" = "yum" ]; then \
		$(ECHO) sudo yum install -y $$1; \
	fi && \
	if [ "$(PKG_MANAGER)" = "apt-get" ]; then \
		$(ECHO) sudo apt-get install -y $$1; \
	fi && \
	if [ "$(PKG_MANAGER)" = "apk" ]; then \
		$(ECHO) apk add --no-cache $$1; \
	fi && \
	if [ "$(PKG_MANAGER)" = "brew" ]; then \
		$(ECHO) brew install $$1; \
	fi \
} && \
for p in $$($(ECHO) '$1'); do \
	export PACKAGE_NAME=$$($(ECHO) $$p | grep -oE '^[^|]+') && \
	if $(WHICH) $$PACKAGE_NAME $(NOOUT); then \
		continue; \
	elif [ "$(DEPS_AUTOINSTALL)" != "1" ]; then \
		export DEP_MISSING=1; \
	fi && \
	export PACKAGE_TMP=$$($(ECHO) $$p | sed 's/^[^|]\+|//g') && \
	export PACKAGE_INSTALL=$$($(ECHO) $$PACKAGE_TMP | grep -oE '[^|]+$$') && \
	export PACKAGE_URL=$$($(ECHO) $$PACKAGE_TMP | sed 's/|[^|]\+$$//g') && \
	if [ "$(DEPS_AUTOINSTALL)" = "1" ]; then \
		eval $$([ "$$PACKAGE_INSTALL" != "$$PACKAGE_URL" ] && \
		$(ECHO) "$$($(ECHO) $$PACKAGE_INSTALL | $(SED) 's|+| |g')" || \
		$(ECHO) "$$(pkg_manager_install $${PACKAGE_NAME})") && \
		continue; \
	fi && \
	$(ECHO) "$(YELLOW)"'the package '"$$PACKAGE_NAME"' is required'"$(NOCOLOR)" && \
	if [ "$$PACKAGE_URL" != "$$PACKAGE_NAME" ] && [ "$$PACKAGE_URL" != "" ]; then \
		$(ECHO) && \
		$(ECHO) "you can get \e[1m$${PACKAGE_NAME}\e[0m at $$PACKAGE_URL" && \
		$(ECHO) && \
		$(ECHO) or you can try to install $$PACKAGE_NAME with the following command; \
	else \
		$(ECHO) && \
		$(ECHO) you can try to install $$PACKAGE_NAME with the following command; \
	fi && \
	$(ECHO) && \
	([ "$$PACKAGE_INSTALL" != "$$PACKAGE_URL" ] && \
		$(ECHO) "$(GREEN)    $$($(ECHO) $$PACKAGE_INSTALL | $(SED) 's|+| |g')$(NOCOLOR)" || \
		$(ECHO) "$(GREEN)    $$(pkg_manager_install $${PACKAGE_NAME})$(NOCOLOR)") && \
	$(ECHO); \
done && \
if [ "$$DEP_MISSING" = "1" ]; then \
	$(EXIT) 9009; \
fi
endef

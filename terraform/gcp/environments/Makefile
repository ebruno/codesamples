SUBDIRS		= all_in_one_run \
		  build_container \
		  local_dev

CLEAN_DIRS = .terraform

CLEAN_FILES = project.tfvars

TFSORT := $(shell which tfsort)

.PHONY: clean dist-clean sort

all:

fmt:
	@$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -C ${SUBDIR} fmt;)

sort:
ifdef TFSORT
	 @$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -C  $(SUBDIR) sort;)
else
	@echo "[INFO] tfsort not available, skipping."
	@$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -C ${SUBDIR} $(TFSORT);)
endif
clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(RM) -r ./tmp/*;
	@$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -C ${SUBDIR} clean;)

dist-clean: clean
	 @$(foreach CLEANDIR, $(CLEAN_DIRS),$(RM) -r ${CLEANDIR};)
	 @$(foreach CLEANFILE, $(CLEAN_FILES),$(RM) $(CLEANFILE);)
	 @$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -C  $(SUBDIR) dist-clean;)

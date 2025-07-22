SUBDIRS 	=

CLEAN_DIRS = .terraform

CLEAN_FILES = terraform.tfstate \
              terraform.tfstate.backup

TFFILES     = main.tf \
	    outputs.tf \
	    variables.tf

TFSORT := $(shell which tfsort)


fmt:
	@terraform fmt;

sort:
ifdef TFSORT
	@$(foreach TFFILE,$(TFFILES), $(TFSORT) $(TFFILE);)
else
	@echo "[INFO] tfsort not available, skipping."
endif
clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;

dist-clean: clean
	 @$(foreach CLEANDIR, $(CLEAN_DIRS),$(RM) -r ${CLEANDIR};)
	 @$(foreach CLEANFILE, $(CLEAN_FILES),$(RM) $(CLEANFILE);)
	 @$(foreach SUBDIR, $(SUBDIRS), $(MAKE) -c  $(SUBDIR) dist-clean;)

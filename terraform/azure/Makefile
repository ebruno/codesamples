SUBDIRS		=

SORTDIRS       =

TFSORT := $(shell which tfsort)

.PHONY: clean dist-clean sort fmt

all:

fmt:
	 @$(foreach SUBDIR, $(SORTDIRS), $(MAKE) -C  $(SUBDIR) fmt;)

sort:
ifdef TFSORT
	 @$(foreach SUBDIR, $(SORTDIRS), $(MAKE) -C  $(SUBDIR) sort;)
else
	@echo "[INFO] tfsort not available, skipping."
	@$(foreach SUBDIR, $(SORTDIRS), $(MAKE) -C ${SUBDIR} $(TFSORT);)
endif

clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;
	@$(foreach SUBDIR, ${SUBDIRS}, ${MAKE} -C ${SUBDIR} clean;)

dist-clean:
	   @$(foreach SUBDIR, ${SUBDIRS}, ${MAKE} -C ${SUBDIR} dist-clean;)

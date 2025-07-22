SUBDIRS 	= doc \
		doc_md \
		eb_prettyjson \
		environments \
		setup_project \
                remove_projects \
		list_projects \

SORTDIRS       = environments \
		setup_project \
                remove_projects \
		list_projects \


TFSORT := $(shell which tfsort)

.PHONY: clean dist-clean sort

all:

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

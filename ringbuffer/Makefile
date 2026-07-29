.PHONY: clean dist-clean

# Remove emacs backup and autosave files recursively within the prompts directory
clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;	
	@find prompts -type f \( -name "*~" -o -name "#*#" \) -delete

# dist-clean calls clean to ensure the environment is tidied up
dist-clean: clean

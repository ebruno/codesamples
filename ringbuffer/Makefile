.PHONY: clean dist-clean sync-claude

# Remove emacs backup and autosave files recursively within the prompts directory
clean:
	@find . -maxdepth 1 -name "*~" -exec ${RM} {} \;
	@find . -maxdepth 1 -name "#*#" -exec ${RM} {} \;	
	@find prompts -type f \( -name "*~" -o -name "#*#" \) -delete

# dist-clean calls clean to ensure the environment is tidied up
dist-clean: clean

# Sync .bionic → CLAUDE.md (keep LM Studio Bionic and Claude Code in sync)
sync-claude:
	@cp .bionic CLAUDE.md

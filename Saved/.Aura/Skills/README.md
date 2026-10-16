# Aura Skills

Drop Claude Code-compatible skills in this folder, one directory per skill:

    Skills/
      my-skill/
        SKILL.md     # YAML frontmatter + markdown body

Frontmatter fields Aura uses:
  description              what the skill does + when to use it (drives
                           autonomous invocation by the model)
  when-to-use              extra trigger text appended after the description
  argument-hint            autocomplete hint shown in the / menu
  disable-model-invocation true = only runs when you type /my-skill
  user-invocable           false = hidden from the / menu

The directory name is the command name (/my-skill). The markdown body is
injected into the conversation when the skill is invoked; trailing text after
the command is appended under an "Arguments:" line.

A skill may bundle resource files (scripts, reference docs, templates)
alongside SKILL.md, e.g.:

    Skills/
      my-skill/
        SKILL.md
        reference.md
        scripts/
          do-thing.py

On invocation Aura tells the assistant the skill's directory and lists the
bundled files. The assistant reads references with its file-read tools and runs
scripts with execute_command (which prompts you for approval and is only
available in Agentic/Custom mode). Aura itself never executes anything.

To share skills with your team through version control, make sure your
ignore file does not exclude this folder. UE's stock ignore rules exclude
Saved/, so add a negation:

    # .gitignore / .p4ignore
    Saved/
    !Saved/.Aura/Skills/

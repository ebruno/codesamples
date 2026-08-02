# Update LLM Model Information

You are tasked with updating the model identification file for the ringbuffer project.

## Goal
Update the file `ringbuffer/lm_info` to reflect the current LLM model and system prompt version being used for the current session.

## Instructions
1.  Identify your current model name, quantization (if known), and the system prompt version.
2.  Write this information as a single line of text into the file `ringbuffer/lm_info`.
3.  The format should be: `Model Name (Quantization), System Prompt vX.X`
4.  Overwrite the existing content of `ringbuffer/lm_info` with this new information.

## Example Output in `ringbuffer/lm_info`
`Llama-3.1-70B-Instruct (Q8_0), System Prompt v1.0`

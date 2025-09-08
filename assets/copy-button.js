let blocks = document.querySelectorAll("pre:has(code)");
let copyButtonLabel = "Copy";

blocks.forEach((block) => {
  // Add a copy button to all blocks.
  let div = document.createElement("div");
  div.innerText = "Code";
  let button = document.createElement("button");
  button.innerText = copyButtonLabel;
  div.append(button);
  block.prepend(div);

  // handle click event
  button.addEventListener("click", async () => {
    await copyCode(block, button);
  });
});

async function copyCode(block, button) {
  let code = block.querySelector("code");
  let text = code.innerText;

  await navigator.clipboard.writeText(text);

  // visual feedback that task is completed
  button.innerText = "Code Copied";

  setTimeout(() => {
    button.innerText = copyButtonLabel;
  }, 700);
}

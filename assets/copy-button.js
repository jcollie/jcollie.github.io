let blocks = document.querySelectorAll("pre:has(code)");
let copyButtonLabel = "Copy";

blocks.forEach((block) => {
  block.classList.add("code-pre");

  // Add a copy button to all blocks.
  let code = block.querySelector("code");
  code.classList.add("code-content");
  let code_content_wrapper = document.createElement("div");
  code_content_wrapper.classList.add("code-content-wrapper");
  code_content_wrapper.append(code);

  let wrapper = document.createElement("div");
  wrapper.classList.add("code-wrapper");

  let header_outer = document.createElement("div");
  header_outer.classList.add("code-header-outer");
  let header_inner = document.createElement("div");
  header_inner.classList.add("code-header-inner");
  header_inner.innerText = "Code";

  let button = document.createElement("button");
  button.innerText = copyButtonLabel;

  header_inner.append(button);
  header_outer.append(header_inner);
  wrapper.append(header_outer);
  wrapper.append(code_content_wrapper);

  block.prepend(wrapper);

  // handle click event
  button.addEventListener("click", async () => {
    await copyCode(code, button);
  });
});

async function copyCode(code, button) {
  let text = code.innerText;

  await navigator.clipboard.writeText(text);

  // visual feedback that task is completed
  button.innerText = "Code Copied";

  setTimeout(() => {
    button.innerText = copyButtonLabel;
  }, 750);
}

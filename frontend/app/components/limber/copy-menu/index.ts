import Component from '@glimmer/component';
import { action } from '@ember/object';

import { toBlob, toPng } from 'html-to-image';

/**
 * This component is injected via the markdown rendering
 */
export default class CopyMenu extends Component {
  @action
  copyAsText(event: Event) {
    let code = getSnippetElement(event);

    navigator.clipboard.writeText(code.innerText);
  }

  @action
  async copyAsImage(event: Event) {
    let code = getSnippetElement(event);

    await withHiddenCopyMenus(() => toClipboard(code));
  }
}

const HIDE_COPY_MENU_CLASS = 'copy-menus-hidden';

export async function withHiddenCopyMenus<Return>(doThis: () => Return | Promise<Return>) {
  document.body.classList.add(HIDE_COPY_MENU_CLASS);

  try {
    await doThis();
  } finally {
    document.body.classList.remove(HIDE_COPY_MENU_CLASS);
  }
}

function getSnippetElement(event: Event) {
  let target = event.target as HTMLElement;

  /**
   * This component has intimate knowledge
   * of how we build markdown previews in
   * markdown-to-ember.ts
   */
  let code = target.closest('.glimdown-snippet')?.querySelector('pre');

  if (!code) {
    return target.closest('[data-test-output]') as HTMLDivElement;
  }

  return code;
}

async function toClipboard(target: HTMLElement) {
  let canCopyToImage = 'ClipboardItem' in window;

  if (!canCopyToImage) {
    let image = new Image();
    let dataUri = await toPng(target);

    image.src = dataUri;

    let w = window.open('');

    w?.document.write(
      `Your browser does not yet support ` +
        `<a target="_blank" href="https://caniuse.com/?search=ClipboardItem">ClipboardItem</a>. <br><br>` +
        image.outerHTML
    );

    return;
  }

  let blob = await toBlob(target);

  // Works in chrome-based browsers only :(
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore
  navigator.clipboard.write([new ClipboardItem({ 'image/png': blob })]);
}

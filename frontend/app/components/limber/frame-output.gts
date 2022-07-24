import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { modifier } from 'ember-modifier';
import { buildWaiter, waitForPromise } from '@ember/test-waiters';

import { DEFAULT_SNIPPET } from 'limber/snippets';
import { parseEvent, fromOutput, formatFrom, type Format } from 'limber/utils/messaging';

import type EditorService from 'limber/services/editor';
import type RouterService from '@ember/routing/router-service';

function makePayload(format: Format, content: string) {
  return { format, content, from: 'limber' } as const;
}

let readyWaiter = buildWaiter('<FrameOutput />:waiting-for-ready');
let compileWaiter = buildWaiter('<FrameOutput />:compiling');

/**
  * The Receiving Component is Limber::Output::Compiler
  */
export default class FrameOutput extends Component {
  @service declare editor: EditorService;
  @service declare router: RouterService;

  @tracked frameStatus: unknown;

  hadUnrecoverableError = false;

  compileFinished = () => {};

  get format() {
    let requested  = this.router.currentRoute.queryParams.format
    return formatFrom(requested);
  }


  /**
    * We can't post right away, because we might do so before the iframe is ready.
    * We need to wait until the frame initiates contact.
    */
  postMessage = modifier((element: HTMLIFrameElement, [_status]) => {
    if (!element.contentWindow) return;

    if (this.hadUnrecoverableError && this.frameStatus === 'ready') {
      this.hadUnrecoverableError = false;

      // this reloads the frame
      element.src = `/output?format=${this.format}`;

      return;
    }

    let qps = this.router.currentURL.split('?')[1];
    let searchParams = new URLSearchParams(qps);
    let text = searchParams.get('t') || DEFAULT_SNIPPET;
    let format = formatFrom(searchParams.get('format'));
    let payload = makePayload(format, text);

    if (this.frameStatus === 'ready') {
      waitForPromise(new Promise(resolve => this.compileFinished = resolve));
    }

    element.contentWindow.postMessage(JSON.stringify(payload));
  });

  onMessage = modifier(() => {
    let ready;
    waitForPromise(new Promise(resolve => ready = resolve));

    let handle = (event: MessageEvent) => {
      let obj = parseEvent(event);

      if (fromOutput(obj)) {
        switch (obj.status) {
          case 'ready':
            ready();
            this.frameStatus = 'ready';
            break;
          case 'error':
            this.editor.error = obj.error;
            this.editor.isCompiling = false;
            if ('unrecoverable' in obj) {
              this.hadUnrecoverableError = true;
            }
            this.compileFinished();
            break;
          case 'compile-begin':
            this.editor.isCompiling = true;
            break;
          case 'success':
            this.editor.error = undefined;
            this.editor.isCompiling = false;
            this.compileFinished();
            break;
        }
      }
    };

    window.addEventListener('message', handle);

    return () => window.removeEventListener('message', handle);
  });

  <template>
    <iframe
      {{this.postMessage this.frameStatus}}
      {{this.onMessage}}
      class="w-full h-full border-none"
      src="/output?format={{this.format}}"></iframe>
  </template>
}

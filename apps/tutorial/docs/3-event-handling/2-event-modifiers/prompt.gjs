import { on } from '@ember/modifier';
import { cell } from 'ember-resources';

let clicks = cell(0);

function handleClick(mouseEvent) {
  clicks.current++;
}

<template>
  <button {{on 'click' handleClick}}>
    Click me!
  </button>

  Clicked: {{clicks.current}}
</template>

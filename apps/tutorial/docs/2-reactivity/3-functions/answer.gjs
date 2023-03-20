import { cell } from 'ember-resources';

const greeting = cell("Hello there!");
const shout = (text) => text.toUpperCase();

// Change the value after 3 seconds
setTimeout(() => {
  greeting.current = "General Kenobi!";
}, 3000);

<template>
  Greeting: {{ (shout greeting.current) }}
</template>

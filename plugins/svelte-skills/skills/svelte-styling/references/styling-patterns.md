# Svelte CSS Styling Patterns

## Scoped Styles

All CSS in `<style>` is scoped to the component automatically. Svelte
adds unique class selectors at compile time.

```svelte
<!-- This h1 style only affects THIS component -->
<h1>Hello</h1>

<style>
	h1 {
		color: blue;
	}
</style>
```

## style: Directive

Set individual CSS properties dynamically. Prefer over inline `style`
strings.

```svelte
<script>
	let color = $state('red');
	let size = $state(16);
</script>

<!-- Individual properties -->
<p style:color style:font-size="{size}px">Styled text</p>

<!-- CSS custom properties -->
<div style:--theme-color={color} style:--columns={3}>
	{@render children()}
</div>

<style>
	div {
		background: var(--theme-color);
		grid-template-columns: repeat(var(--columns), 1fr);
	}
</style>
```

### style: vs inline style

```svelte
<!-- Prefer style: directive -->
<div style:color={textColor} style:font-size="{size}px">Good</div>

<!-- Avoid inline style strings -->
<div style="color: {textColor}; font-size: {size}px">Avoid</div>
```

**Why:** `style:` directives are type-checked, support shorthand, and
merge cleanly with static styles.

### Shorthand

When variable name matches property name:

```svelte
<script>
	let color = $state('red');
</script>

<p style:color>Shorthand</p>
<!-- Equivalent to style:color={color} -->
```

### Important modifier

```svelte
<p style:color|important="red">Override</p>
```

## CSS Custom Properties for Child Components

The preferred way to style child components from a parent.

### Basic Pattern

```svelte
<!-- Parent.svelte -->
<Card --bg="navy" --text="white" --radius="8px" />

<!-- Card.svelte -->
<div class="card">
	{@render children()}
</div>

<style>
	.card {
		background: var(--bg, #fff);
		color: var(--text, #000);
		border-radius: var(--radius, 4px);
	}
</style>
```

### Theming Pattern

```svelte
<!-- ThemeProvider.svelte -->
<div
	style:--primary={theme.primary}
	style:--secondary={theme.secondary}
	style:--font={theme.font}
>
	{@render children()}
</div>

<!-- Any descendant can use var(--primary) etc. -->
```

### On Elements vs Components

```svelte
<!-- On elements: sets the property on the element -->
<div style:--color="red">...</div>

<!-- On components: wraps in <div style="--color: red"> -->
<Component --color="red" />
```

## :global Selectors

Override scoped styles. Use sparingly.

### Scoped :global (Recommended)

Limit `:global` to a parent selector scope:

```svelte
<div class="wrapper">
	<LibraryComponent />
</div>

<style>
	.wrapper :global {
		/* Only affects children of .wrapper */
		h1 {
			color: red;
		}
		.library-class {
			padding: 1rem;
		}
	}
</style>
```

### Inline :global (Use Sparingly)

```svelte
<style>
	/* Affects ALL h1 elements on the page */
	:global(h1) {
		font-family: serif;
	}

	/* Target a specific global class within scoped context */
	.card :global(.highlight) {
		background: yellow;
	}
</style>
```

### :global Block

```svelte
<style>
	:global {
		/* Everything here is unscoped — like a regular stylesheet */
		body {
			margin: 0;
		}
	}
</style>
```

**Warning:** Unscoped `:global` affects the entire page. Prefer scoped
`:global` inside a parent selector.

## class: Directive

Conditionally apply classes:

```svelte
<script>
	let active = $state(false);
</script>

<button
	class:active
	class:disabled={!enabled}
	onclick={() => active = !active}
>
	Toggle
</button>

<style>
	.active {
		background: blue;
		color: white;
	}
	.disabled {
		opacity: 0.5;
	}
</style>
```

### Shorthand

When variable name matches class name:

```svelte
<div class:active>...</div>
<!-- Equivalent to class:active={active} -->
```

## Conditional and Dynamic Styles

### Pattern: Theme Switcher

```svelte
<script>
	let dark = $state(false);
</script>

<div class:dark style:--bg={dark ? '#1a1a1a' : '#fff'}>
	{@render children()}
</div>

<style>
	div {
		background: var(--bg);
		transition: background 0.3s;
	}
</style>
```

### Pattern: Responsive Grid

```svelte
<script>
	let columns = $state(3);
</script>

<div style:--cols={columns}>
	{#each items as item}
		<div class="cell">{item}</div>
	{/each}
</div>

<style>
	div {
		display: grid;
		grid-template-columns: repeat(var(--cols, 3), 1fr);
		gap: 1rem;
	}
</style>
```

## Best Practices Summary

1. **Scoped by default** — component `<style>` only affects that
   component
2. **Use `style:` directive** — not inline style strings for dynamic
   values
3. **CSS custom properties** — preferred way to style child components
4. **Scoped `:global`** — always wrap in a parent selector when possible
5. **`class:` directive** — for conditional class application
6. **Avoid broad `:global`** — can cause style leaks across the app

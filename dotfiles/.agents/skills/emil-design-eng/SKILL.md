---
name: emil-design-eng
description: Emil Kowalski の設計観点で、UI の操作感・細部・コンポーネントを実装またはレビューする。特定のモーション実装だけなら animate を使う。
---

# UI の操作感と細部

利用頻度・操作目的・既存のデザインに照らして判断する。ユーザーのフィードバックを遅らせず、中断・再操作・状態変化に自然に追従させる。既存の値や構造を好みだけで置き換えない。

- コンポーネントのAPI・余白・hover・hit area・ロード状態は [components.md](references/components.md) の該当箇所を読む。
- easing・spring・transform・clip-path・ジェスチャー・staggerは [motion.md](references/motion.md) の該当箇所を読む。掲載値は出発点とし、既存tokenと実際の操作感を優先する。
- 指摘は場所、起きる問題、ユーザーへの影響、修正案を具体的に示す。コードだけで判断できない感触は、ブラウザで確認する。

## Performance Rules

### Prefer transform and opacity

Transform and opacity can avoid layout and paint. Height or clip-path can be appropriate for bounded components; check their cost in the target browser and layout.

### CSS variables are inheritable

Changing a CSS variable on a parent recalculates styles for all children. In a drawer with many items, updating `--swipe-amount` on the container causes expensive style recalculation. Update `transform` directly on the element instead.

```js
// Bad: triggers recalc on all children
element.style.setProperty('--swipe-amount', `${distance}px`);

// Good: only affects this element
element.style.transform = `translateY(${distance}px)`;
```

### Check the execution path

Library acceleration depends on the version, browser, properties, and animation type. Inspect the generated animation and profile under representative load before replacing library shorthands.
CSS or WAAPI can suit predetermined motion; transitions and springs can suit retargetable interactions. Neither API choice alone guarantees smooth rendering.

## Accessibility

### prefers-reduced-motion

Honor reduced-motion preferences by removing unnecessary movement. Use instant state changes or gentle opacity/color feedback when appropriate; preserving animation is not a requirement.

```css
@media (prefers-reduced-motion: reduce) {
  .element {
    animation: fade 0.2s ease;
    /* No transform-based motion */
  }
}
```

```jsx
const shouldReduceMotion = useReducedMotion();
const closedX = shouldReduceMotion ? 0 : '-100%';
```

### Touch device hover states

```css
@media (hover: hover) and (pointer: fine) {
  .element:hover {
    transform: scale(1.05);
  }
}
```

Touch devices trigger hover on tap, causing false positives. Gate hover animations behind this media query.

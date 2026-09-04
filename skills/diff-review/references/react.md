# React / TypeScript review checklist

Read this only when the diff touches `.tsx`, `.jsx`, or React hooks. Findings here slot into the same severity ranking as the core standards.

## Effects are the #1 thing to flag

`useEffect` is an escape hatch for synchronizing with systems *outside* React. Most effects in a PR are not that. For every `useEffect` in the diff, ask which of these it is:

1. **Derived state — flag as Should fix.** State + an effect that recomputes it from props/other state. Delete both; compute during render. If it's genuinely expensive (measure first), `useMemo` it.
   ```tsx
   // flag this
   const [fullName, setFullName] = useState('')
   useEffect(() => { setFullName(`${first} ${last}`) }, [first, last])
   // want this
   const fullName = `${first} ${last}`
   ```
2. **Responding to an event — flag as Should fix.** Effect fires because a user did something (submitted, clicked, toggled). That logic belongs in the event handler, where you know *why* it ran. Effects can't tell a click from a remount.
3. **Chained/cascading effects — flag as Blocker-adjacent.** Effect A sets state that triggers effect B. Each link is an extra render pass and a place for a stale intermediate to render. Collapse into one computation or one handler.
4. **Resetting state when a prop changes — flag.** Usually wants a `key` on the component instead, letting React remount it.
5. **Legitimately external** — DOM subscriptions, timers, non-React widgets, analytics, manual data fetches. Fine. Now check its cleanup.

## Effect hygiene (when the effect survives the above)

- **Missing cleanup.** Subscriptions, timers, listeners, observers must return a teardown. No teardown = leak on unmount.
- **Async race.** `await fetch(...)` then `setState` with no cancel/ignore flag or `AbortController`: two in-flight requests can resolve out of order and the stale one wins. Flag as Blocker — it's a real data-correctness bug, not style.
- **Lying dependency array.** Deps that don't match what the body reads, or eslint-disable on the deps rule with no comment explaining why. The disable is the finding.
- **Unstable deps.** Object/array/function literals in the deps array re-trigger every render. Either memoize the dep or restructure.
- **Data fetching in an effect** where the stack already provides a loader / server component / react-query. Flag the missed convention.

## Hooks and state generally

- **`useState` that should be `useRef`** — a value that isn't rendered doesn't need to trigger renders.
- **State duplicated from props** (`useState(props.x)`) with no intent to fork it. That's a stale copy waiting to happen.
- **Conditional or looped hooks.** Blocker, breaks the rules of hooks.
- **State lifted higher than any consumer needs** — or drilled through 4 layers when colocating or context would do.
- **Context value built inline** (`value={{ user, setUser }}`) — new object every render, every consumer re-renders. Memoize.
- **Cargo-culted `useMemo`/`useCallback`.** Wrapping a cheap computation adds allocation + dep-array surface for nothing. Flag if there's no memoized child or expensive body justifying it. (Nit, not a blocker.)

## Rendering

- **`key={index}`** on a list that can reorder, filter, or delete. Causes state to attach to the wrong row. Blocker if the rows hold state.
- **Missing loading/error/empty states.** A component that fetches renders three states minimum; if the diff only handles success, it's incomplete.
- **Effects/handlers that assume the component is mounted** after an await.

## TypeScript

- **`any` or `as` casts** that paper over a real type mismatch — the cast is where the bug will live.
- **Non-null assertion (`!`)** on anything derived from network or user input.
- **Types that lie** — optional fields marked required, or a union that doesn't model the actual states (loading/error/success as three booleans instead of a discriminated union).

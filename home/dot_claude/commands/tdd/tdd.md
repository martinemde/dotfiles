Follow the Test-Driven Development (TDD) red-green-refactor cycle for implementing $ARGUMENTS.

## Red-Green-Refactor Workflow

### 1. RED - Write a Failing Test

- Write a single, focused test for the next small behavior
- Run the test suite to confirm it fails with the expected error
- Verify the failure message is clear and meaningful

### 2. GREEN - Make It Pass

- Write the minimal code needed to make the test pass
- Avoid gold-plating or premature optimization
- Run the test suite to confirm the test now passes
- All existing tests must still pass

### 3. REFACTOR - Improve the Design

- Clean up any duplication or code smells
- Improve naming, structure, and clarity
- Run the test suite after each refactoring step
- Ensure all tests remain green throughout

## Cycle Rules

- One test at a time - resist writing multiple tests before implementation
- Smallest possible steps - each cycle should take minutes, not hours
- Test coverage follows naturally - no need to track coverage metrics separately
- Commit after each green refactor - maintain working state in version control

## Implementation Steps

1. Understand the requirement from $ARGUMENTS
2. Identify the first testable behavior (start small)
3. Execute RED: Write failing test
4. Execute GREEN: Minimal implementation
5. Execute REFACTOR: Clean up
6. Repeat steps 2-5 for the next behavior until complete

Run tests using the project's standard test command. Ask if unclear about test framework or location.

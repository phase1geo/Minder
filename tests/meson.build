test_vala_sources = [
  'assert.vala',
  'tests.vala',
  'test-example.vala',
]

test_executable = executable(
  'minder-regress',
  test_vala_sources,
  dependencies: dependencies,
)

test(
  'minder-regress',
  test_executable,
)

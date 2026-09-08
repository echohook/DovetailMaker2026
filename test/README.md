# Regression checks

Run `ruby test/regression.rb` with Ruby 3.2. The test uses geometry/API doubles;
it does not simulate SketchUp's push/pull solid editing engine.

It exercises legacy first-end-only metadata, recovery of actual opposite-end
profiles, asymmetric half pins, Group/Component selection, current instance
transforms, matching both Pin ends, rejection of distant or already-cut faces,
and reopening the controller without recalculating a Tail layout.

Serve the repository locally and open `test/dialog_fixture.html` to check the
real HTML/CSS in a fixed 440 × 540 content area. The fixture supplies a mock Ruby
bridge; each mode reports overflow and clipped controls. Check Tail, Select Pin,
Resume, Pin, Complete and About. Also clear/retype a numeric field and use its
arrow keys. This fixture is excluded from the RBZ.

For a native SketchUp acceptance check, use a disposable model: make two equal-
thickness rectangular boards at an assembled 90° corner, create Tail/Pin,
enable the opposite Tail option, then finish. Add a mating board at the other
end, reselect the existing Tail board and restart the extension. Verify a red
preview on the new Pin board and complete the cut. Repeat after saving/reopening
and after rotating/moving both boards together. Check both boards remain solids.

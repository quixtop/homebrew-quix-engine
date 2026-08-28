# Homebrew formula for the strm engine.
#
# ⚠️ THIS IS THE DISTRIBUTION DECISION, not a convenience wrapper (27Aug26). The engine binary is
# UNSIGNED and un-notarized. macOS attaches a quarantine attribute to anything a BROWSER downloads,
# and Gatekeeper then refuses to run it — so a plain "download the binary" link is broken on every
# Mac unless we buy an Apple Developer account and build a notarization pipeline. `brew` fetches
# over curl, which sets no quarantine attribute, so the same file installs and runs untouched.
# That is why distribution goes through a tap rather than a release link or `curl | sh`.
#
# ⚠️ `curl | sh` was considered and REJECTED. It solves nothing Gatekeeper-wise (the script still has
# to place a binary), and piping a remote script into a shell contradicts what this project enforces
# everywhere else — SSRF guards at 21 call sites, sealed keys at rest, a refusal to dial cleartext.
#
# ⚠️ Publishable once the release exists: hashes are real (28Aug26); the URLs resolve after the
# release. Hashes below are FILLED from the generated SHA256SUMS-0.1.0.txt (28Aug26) — never
# hand-transcribed from a separate shasum run.
#
# ⚠️ THE ORG IS `quixtop`, NOT `slashlabs` (owner 27Aug26). `slashlabs.cc` is a REALM — a domain the
# workers serve — and has never been a GitHub org; the two are unrelated and an install line naming
# the wrong one fails with brew's least helpful error ("no available formula").
#
# ⚠️ The tap repo MUST carry the `homebrew-` prefix: `github.com/quixtop/homebrew-quix-engine`.
# brew derives the repo name from the tap name by adding it, so a repo called plain `quix-engine`
# is invisible to `brew install quixtop/quix-engine`.
#
# ⚠️ RELEASES ARE HOSTED IN THE TAP REPO ITSELF, deliberately. The code lives in shrix/cf-worx, and
# pointing the formula there would mean a second repo, a second release process, and a public
# download URL under a personal account rather than the product's org. One repo holds the formula
# and the binaries it pins; there is nothing to keep in step across two.
#
# To publish: create `github.com/quixtop/homebrew-quix-engine`, drop this file in as
# `Formula/quix-engine.rb`, attach the binaries from `bin/quix engine-build` to a release there,
# and fill in the hashes from the generated SHA256SUMS file. Then:
#     brew install quixtop/quix-engine
class QuixEngine < Formula
  desc "Local engine for quix — Telegram and Gmail for the strm web client"
  homepage "https://quixtop.com"
  version "0.1.0"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/quixtop/homebrew-quix-engine/releases/download/v#{version}/quix-engine-#{version}-darwin-arm64"
      sha256 "2d72dc83953687a8df438d96f45ad31413f6cf97ae6ec770ddc988a6eb0af8f9"
    end
    on_intel do
      url "https://github.com/quixtop/homebrew-quix-engine/releases/download/v#{version}/quix-engine-#{version}-darwin-x64"
      sha256 "56ffee632fb732228558c9bde356643a26ee71ff9e5a3938b8693bc5c5c83c41"
    end
  end

  # ⚠️ ARCH-BRANCHED, like macOS. brew is the MAC path by decision (Linux/Windows use the direct
  # download), but Homebrew does run on Linux and an unbranched block would hand a Raspberry Pi the
  # x64 binary — which fails at exec with a message that explains nothing.
  # ⚠️ Homebrew on Linux may not support arm64 at all; if so this block simply never fires, which is
  # harmless. It is here so that a Pi is never served the WRONG artifact, not to promise brew works
  # there — the Pi's supported path is the direct download.
  on_linux do
    on_arm do
      url "https://github.com/quixtop/homebrew-quix-engine/releases/download/v#{version}/quix-engine-#{version}-linux-arm64"
      sha256 "75623e68110c4af4eee1766a13e0baad5cc56d9c7bff0e791fb618c03fa52839"
    end
    on_intel do
      url "https://github.com/quixtop/homebrew-quix-engine/releases/download/v#{version}/quix-engine-#{version}-linux-x64"
      sha256 "ecb1e50c6bd1308e23d5e97b1b8631ca06fade1e4e91c3300edd94a5c5fcad84"
    end
  end

  def install
    # The downloaded artifact keeps its platform-stamped name; install it under the plain command.
    bin.install Dir["quix-engine-*"].first => "quix-engine"
  end

  # ⚠️ NOT a `service` block, deliberately. A launchd service would start the engine at boot on
  # every machine that installs it — but the engine is PER-DEVICE and ON-DEMAND by design: exactly
  # one may host at a time, the hub arbitrates, and a move is always an explicit user click. An
  # always-on service on several machines would have them fighting for the same slot, which is the
  # one behaviour the on-demand design exists to prevent.

  def caveats
    <<~EOS
      The engine needs its own config before it will start. Pair it with your account:

        quix-engine --help

      State (session files) is kept in:
        ~/Library/Application Support/quix        (macOS)
        ~/.local/share/quix                       (Linux)

      Override with QUIX_DATA_DIR if you want it elsewhere.

      This binary is unsigned. Installing through brew is what keeps macOS from
      quarantining it — downloading the same file in a browser will not work.
    EOS
  end

  test do
    # ⚠️ Asserts it STARTS and reaches its own config check, not that it connects: a test that needs
    # Telegram credentials cannot run in Homebrew's CI, and one that needs the network is flaky by
    # construction. Reaching "missing env" proves the binary loaded and its runtime is intact —
    # which is the exact failure mode a bad cross-compile produces.
    output = shell_output("#{bin}/quix-engine 2>&1", 1)
    assert_match "missing env", output
  end
end

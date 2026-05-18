# frozen_string_literal: true

require "test_helper"
require "yaml"

# Phase 88 (v1.26 planning/traceability closure) — deterministic checks on
# planning artifacts touched for REQUIREMENTS parity, SUMMARY tooling keys, and
# Cucumber stability hooks. Complements functional coverage in Rails tests + Cucumber.

class V126ClosurePlanningContractTest < ActiveSupport::TestCase
  REQUIREMENTS_MD = Rails.root.join(".planning/REQUIREMENTS.md")

  SUMMARY_REQ_COMPLETED = {
    ".planning/phases/84-data-layer-controller/84-01-SUMMARY.md" => %w[DAT-01 DAT-02 DAT-03],
    ".planning/phases/84-data-layer-controller/84-02-SUMMARY.md" => ["DAT-04"],
    ".planning/phases/85-css-view-helper/85-01-SUMMARY.md" => %w[VIS-01 VIS-02],
    ".planning/phases/86-gadget-controller-view-wiring/86-01-SUMMARY.md" =>
      %w[GAD-01 GAD-02 GAD-03 GAD-04],
    ".planning/phases/86-gadget-controller-view-wiring/86-02-SUMMARY.md" =>
      %w[GAD-01 GAD-02 GAD-03 GAD-04],
    ".planning/phases/87-js-click-handler/87-01-SUMMARY.md" => %w[JS-01 JS-02],
    ".planning/phases/87-js-click-handler/87-02-SUMMARY.md" => %w[JS-01 JS-02],
  }.freeze

  test "v1.26 traceability section contains no TBD placeholders" do
    body = REQUIREMENTS_MD.read
    trace = subsection_after_heading(body, "## Traceability")
    refute_match(/TBD/i, trace, "concrete PLAN paths required in traceability table")
    refute(trace.strip.empty?)
  end

  test "DAT-01 bullets document InnoDB-compatible 767-byte url prefix index" do
    line = requirements_bullet_matching(/^\s*\- \[x\] \*\*DAT-01\*\*:/)
    assert_match(%r{(user_id, url\(767\))|767-byte utf8mb4}, line)
  end

  test "DAT-04 bullets document CSRF-aware 204 and Devise redirect (302)" do
    line = requirements_bullet_matching(/^\s*\- \[x\] \*\*DAT-04\*\*:/)
    assert_match(/\b302\b/, line)
    assert_match(/\b204\b/, line)
    assert_match(/CSRF/, line)
    assert_match(/401/, line, "DAT-04 should clarify HTML flow vs naive 401")
  end

  SUMMARY_REQ_COMPLETED.each do |relative_path, expected|
    test "#{relative_path} declares requirements-completed for #{expected.join(', ')}" do
      path = Rails.root.join(relative_path)
      fm = yaml_frontmatter!(path.read)
      key = fm.fetch("requirements-completed") do
        fm["requirements_completed"] # legacy / underscore tolerated
      end
      assert_kind_of Array, key, path.to_s
      assert_equal expected, key.map(&:to_s)
    end
  end

  test "roadmap marks v1.26 shipped with phase 88 plan complete" do
    roadmap = Rails.root.join(".planning/ROADMAP.md").read
    assert_match(/✅ \*\*v1\.26 — Visited Link Tracking\*\*/, roadmap)
    assert_match(/✅ .*Phases 84–88 .*shipped 2026-05-18/, roadmap)
    assert_match(/- \[x\] 88-01-PLAN\.md/, roadmap)
    assert_match(%r{v1\.26.*\|\s*1/1\s*\|\s*Complete}, roadmap)
  end

  test "features/support hooks restore desktop viewport stability for Cucumber isolation" do
    body = Rails.root.join("features/support/hooks.rb").read
    assert_match(/portal_column_widths:\s+Preference\.equal_portal_column_widths\(3\)/, body)
    assert_match(/resize_browser_window\(1280, 800\)/, body)
    assert_match(/mobile_portal/, body)
    assert_match(/VisitedLink\.delete_all/, body)
  end

  private

  def requirements_bullet_matching(start_re)
    REQUIREMENTS_MD.read.each_line do |line|
      return line.strip if line.match?(start_re)
    end
    flunk "No matching DAT bullet found in REQUIREMENTS.md"
  end

  def subsection_after_heading(markdown, heading)
    ix = markdown.index(heading)
    flunk("missing #{heading}") unless ix

    after = markdown[(ix + heading.length)..]
    nix = after.index(/\n## /)
    chunk = (nix.nil? ? after : after[0...nix])
    chunk.strip
  end

  def yaml_frontmatter!(file_contents)
    m = file_contents.match(/\A---\s*\n(.*?)^(---)\s*\n/m)
    flunk "missing YAML frontmatter" unless m

    YAML.safe_load(
      m[1],
      permitted_classes: [],
      permitted_symbols: [],
      aliases: false
    ) || {}
  rescue Psych::SyntaxError => e
    flunk("invalid frontmatter YAML: #{e.message}")
  end
end

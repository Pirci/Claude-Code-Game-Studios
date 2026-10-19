# Godot Engine — Version Reference

| Field | Value |
|-------|-------|
| **Engine Version** | Godot 4.7 |
| **Release Date** | 2026-06-18 (4.7 stable; 4.7.1 patch used for verification) |
| **Project Pinned** | 2026-07-13 |
| **Last Docs Verified** | 2026-10-19 |
| **Verified Binary** | Godot 4.7.1 stable (`a13da4feb`), Linux x86_64, headless |
| **LLM Knowledge Cutoff** | May 2025 |

## Knowledge Gap Warning

The LLM's training data likely covers Godot up to ~4.3. Versions 4.4, 4.5,
4.6, and 4.7 introduced significant changes that the model does NOT know about.
Always cross-reference this directory before suggesting Godot API calls.

## Post-Cutoff Version Timeline

| Version | Release | Risk Level | Key Theme |
|---------|---------|------------|-----------|
| 4.4 | ~Mid 2025 | MEDIUM | Jolt physics option, FileAccess return types, shader texture type changes |
| 4.5 | ~Late 2025 | HIGH | Accessibility (AccessKit), variadic args, @abstract, shader baker, SMAA, VisibleOnScreenNotifier2D `show_rect` option |
| 4.6 | Jan 2026 | HIGH | Jolt default, glow rework, D3D12 default on Windows, IK restored |
| 4.7 | 2026-06-18 | MEDIUM | HDR output, Control offset transforms, DrawableTexture2D, AreaLight3D, Tween.tween_await, keyboard/mouse device IDs, PopupMenu search bar, standalone Android export (GABE), new Asset Store. Small breaking surface (migration guide: "relatively safe" for 4.6 projects) but post-cutoff - see breaking-changes.md |

## Verified Sources

Used for the 4.7 refresh on 2026-10-19 (all fetched successfully):

- Official docs: https://docs.godotengine.org/en/stable/
- 4.6→4.7 migration guide: https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html
- 4.7 release notes: https://godotengine.org/releases/4.7/
- Changelog (section "4.7 - 2026-06-18"): https://github.com/godotengine/godot/blob/master/CHANGELOG.md
- 4.5→4.6 migration guide + 4.6 release notes (to attribute 4.6 vs 4.7 changes):
  https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.6.html , https://godotengine.org/releases/4.6/
- Class reference (importer defaults): https://docs.godotengine.org/en/stable/classes/
- Local verification: Godot 4.7.1 stable binary, `--headless --dump-extension-api` + headless GDScript checks (ClassDB / ProjectSettings queries)

Earlier references: 4.4→4.5 migration https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.5.html

## Re-verification Notes

- Items marked "verified" in this directory were checked on the 4.7.1 binary on 2026-10-19; items marked
  "changelog" / "migration guide" / "release notes" come only from those documents.
- Deprecation markers are NOT readable from the stripped binary (`--doctool` output has no `deprecated=` attributes);
  deprecations in `deprecated-apis.md` come from the changelog.

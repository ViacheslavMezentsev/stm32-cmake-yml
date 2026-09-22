# Profiles

[Documentation](../../index.md) → [Reference 0.9.2](index.md) → Profiles · [Русский](../../../ru/reference/0.9.2/profiles.md)

Shared rules: [semantics](semantics.md). Baseline: `f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0`. Introduction history before 0.9.2 is not established; presence is confirmed in this baseline. Unless stated otherwise, configuration happens at Configure/Generate and actual commands execute at Build/Post-build.

<a id="profiles"></a>
## `profiles`

`CFG-PROFILES` · **Type:** mapping: name -> option mapping · **Default:** {}

Named sets selected by -DSTM32_YML_PROFILE=name. A key replaces its base value; _append extends the already replaced list. Nested keys flatten with underscores. Unknown profiles warn and continue with base configuration. Use letters/digits without _ or regex metacharacters for portable names.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
profiles:
  debug:
    stack_size: 2K
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.profile-replace-and-append`, `configure.unknown-profile-warning`, `configure.reconfigure-profile-lists`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E005](../../errata/E005.md).

<a id="profiles-file"></a>
## `profiles_file`

`CFG-PROFILES-FILE` · **Type:** string: relative YAML path · **Default:** inline profiles

External root-relative YAML file containing profiles. Selection loads it as the profile source; a merge of both profile catalogs is not guaranteed. A missing file warns. Baseline 0.9.2 list does not read this file.

**Omission and emptiness:** see [shared rules](semantics.md#empty-values); exceptions are stated above. Profiles/overrides apply before defaults. Backend/path restrictions are stated in the description.

```yaml
profiles_file: profiles.yml
```

[0.9.2 implementation](https://github.com/ViacheslavMezentsev/stm32-cmake-yml/blob/f8ef5200fc7a4a96d6f3fe9111afb8f8825474b0/cmake/stm32_yml_profiles.cmake) · [Index](index.md)

**Checks (partial coverage):** `configure.external-profile`. [Test manifest](../../../../tests/cases.json).

**Errata:** [E002](../../errata/E002.md).

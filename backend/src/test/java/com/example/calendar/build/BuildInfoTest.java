package com.example.calendar.build;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Map;
import java.util.Properties;
import org.junit.jupiter.api.Test;

class BuildInfoTest {

  private static final String FULL_SHA = "0123456789abcdef0123456789abcdef01234567";

  private static BuildInfo from(Properties gitProperties, Map<String, String> environment) {
    return BuildInfo.from(gitProperties, environment::get);
  }

  @Test
  void gitPropertiesWinOverEnvironment() {
    Properties gitProperties = new Properties();
    gitProperties.setProperty("git.commit.id.full", FULL_SHA);
    gitProperties.setProperty("git.branch", "main");
    gitProperties.setProperty("git.build.time", "2026-11-23T10:15:30+0300");

    BuildInfo info =
        from(
            gitProperties,
            Map.of(
                "RAILWAY_GIT_COMMIT_SHA", "ffffffffffffffffffffffffffffffffffffffff",
                "RAILWAY_GIT_BRANCH", "railway-branch"));

    assertThat(info.commit()).isEqualTo(FULL_SHA);
    assertThat(info.commitShort()).isEqualTo("0123456");
    assertThat(info.branch()).isEqualTo("main");
    assertThat(info.builtAt()).isEqualTo("2026-11-23T07:15:30Z");
  }

  @Test
  void railwayVariablesIdentifyBuildWithoutGitDirectory() {
    BuildInfo info =
        from(
            new Properties(),
            Map.of("RAILWAY_GIT_COMMIT_SHA", FULL_SHA, "RAILWAY_GIT_BRANCH", "main"));

    assertThat(info.commit()).isEqualTo(FULL_SHA);
    assertThat(info.commitShort()).isEqualTo("0123456");
    assertThat(info.branch()).isEqualTo("main");
    assertThat(info.builtAt()).isEqualTo(BuildInfo.UNKNOWN);
  }

  @Test
  void missingMetadataIsReportedAsUnknown() {
    BuildInfo info =
        from(new Properties(), Map.of("RAILWAY_GIT_COMMIT_SHA", "", "GIT_COMMIT", "   "));

    assertThat(info.commit()).isEqualTo(BuildInfo.UNKNOWN);
    assertThat(info.commitShort()).isEqualTo(BuildInfo.UNKNOWN);
    assertThat(info.branch()).isEqualTo(BuildInfo.UNKNOWN);
    assertThat(info.builtAt()).isEqualTo(BuildInfo.UNKNOWN);
  }
}

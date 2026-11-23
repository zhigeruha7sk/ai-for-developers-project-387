package com.example.calendar.build;

import java.io.IOException;
import java.io.InputStream;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.Properties;
import java.util.function.Function;

/**
 * Идентификация сборки: коммит, ветка и время сборки.
 *
 * <p>Источники по убыванию точности: {@code git.properties}, который пишет
 * git-commit-id-maven-plugin при сборке jar; затем переменные Railway ({@code
 * RAILWAY_GIT_COMMIT_SHA}, {@code RAILWAY_GIT_BRANCH}) — Docker-образ собирается без каталога
 * {@code .git}; затем общие {@code GIT_COMMIT} и {@code GIT_BRANCH} для прочих сборок. Если
 * метаданных нет, значение равно {@link #UNKNOWN}.
 */
public final class BuildInfo {

  /** Значение, когда метаданных сборки нет. */
  public static final String UNKNOWN = "unknown";

  private static final String GIT_PROPERTIES = "git.properties";
  private static final int SHORT_COMMIT_LENGTH = 7;
  private static final DateTimeFormatter GIT_BUILD_TIME =
      DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ssZ");

  private final String commit;
  private final String commitShort;
  private final String branch;
  private final String builtAt;

  private BuildInfo(String commit, String commitShort, String branch, String builtAt) {
    this.commit = commit;
    this.commitShort = commitShort;
    this.branch = branch;
    this.builtAt = builtAt;
  }

  /** Читает метаданные текущей сборки. */
  public static BuildInfo load() {
    return from(readGitProperties(), System::getenv);
  }

  static BuildInfo from(Properties gitProperties, Function<String, String> environment) {
    String commit =
        firstValue(
            gitProperties.getProperty("git.commit.id.full"),
            gitProperties.getProperty("git.commit.id"),
            environment.apply("RAILWAY_GIT_COMMIT_SHA"),
            environment.apply("GIT_COMMIT"));
    String branch =
        firstValue(
            gitProperties.getProperty("git.branch"),
            environment.apply("RAILWAY_GIT_BRANCH"),
            environment.apply("GIT_BRANCH"));
    return new BuildInfo(
        commit,
        shortCommit(commit),
        branch,
        formatBuildTime(gitProperties.getProperty("git.build.time")));
  }

  /** Полный SHA коммита или {@link #UNKNOWN}. */
  public String commit() {
    return commit;
  }

  /** Короткий SHA коммита или {@link #UNKNOWN}. */
  public String commitShort() {
    return commitShort;
  }

  /** Ветка сборки или {@link #UNKNOWN}. */
  public String branch() {
    return branch;
  }

  /** Время сборки в ISO 8601 (UTC) или {@link #UNKNOWN}. */
  public String builtAt() {
    return builtAt;
  }

  private static Properties readGitProperties() {
    Properties properties = new Properties();
    try (InputStream stream =
        BuildInfo.class.getClassLoader().getResourceAsStream(GIT_PROPERTIES)) {
      if (stream != null) {
        properties.load(stream);
      }
    } catch (IOException ignored) {
      // Без git.properties /api/version отвечает unknown — это не ошибка запуска.
    }
    return properties;
  }

  private static String firstValue(String... candidates) {
    for (String candidate : candidates) {
      if (candidate != null && !candidate.isBlank()) {
        return candidate.trim();
      }
    }
    return UNKNOWN;
  }

  private static String shortCommit(String commit) {
    if (UNKNOWN.equals(commit)) {
      return UNKNOWN;
    }
    return commit.substring(0, Math.min(SHORT_COMMIT_LENGTH, commit.length()));
  }

  private static String formatBuildTime(String value) {
    if (value == null || value.isBlank()) {
      return UNKNOWN;
    }
    String trimmed = value.trim();
    try {
      return Instant.parse(trimmed).toString();
    } catch (DateTimeParseException ignored) {
      // git-commit-id пишет смещение без двоеточия: 2026-11-23T10:00:00+0300.
    }
    try {
      return OffsetDateTime.parse(trimmed).toInstant().toString();
    } catch (DateTimeParseException ignored) {
      // Ниже — формат самого плагина.
    }
    try {
      return OffsetDateTime.parse(trimmed, GIT_BUILD_TIME).toInstant().toString();
    } catch (DateTimeParseException ignored) {
      return UNKNOWN;
    }
  }
}

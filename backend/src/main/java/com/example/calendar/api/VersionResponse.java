package com.example.calendar.api;

/** Версия сборки приложения. */
public record VersionResponse(String commit, String commitShort, String branch, String builtAt) {}

package com.example.calendar.api;

import com.example.calendar.build.BuildInfo;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api")
public class VersionController {

  private final BuildInfo buildInfo = BuildInfo.load();

  @GetMapping("/version")
  public VersionResponse version() {
    return new VersionResponse(
        buildInfo.commit(), buildInfo.commitShort(), buildInfo.branch(), buildInfo.builtAt());
  }
}

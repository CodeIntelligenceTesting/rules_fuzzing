# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Miscellaneous utilities."""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _generate_file_impl(ctx):
    ctx.actions.write(ctx.outputs.output, ctx.attr.contents)

generate_file = rule(
    implementation = _generate_file_impl,
    doc = """
Generates a file with a specified content string.
""",
    attrs = {
        "contents": attr.string(
            doc = "The file contents.",
            mandatory = True,
        ),
        "output": attr.output(
            doc = "The output file to write.",
            mandatory = True,
        ),
    },
)

# Returns the path of a runfile that can be used to look up its absolute path
# via the rlocation function provided by Bazel's runfiles libraries.
def runfile_path(ctx, runfile):
    return paths.normalize(ctx.workspace_name + "/" + runfile.short_path)

# Based on
# https://github.com/bazelbuild/bazel-skylib/blob/5bfcb1a684550626ce138fe0fe8f5f702b3764c3/rules/common_settings.bzl#L72
def _no_at_str(label):
    """Strips any leading '@'s for labels in the main repo, so that the error string is more friendly."""
    s = str(label)
    if s.startswith("@@//"):
        return s[2:]
    if s.startswith("@//"):
        return s[1:]
    return s

def _repeatable_string_flag_impl(ctx):
    allowed_values = ctx.attr.values
    actual_values = ctx.build_setting_value
    for value in actual_values:
        if value not in allowed_values:
            fail("Error setting " + _no_at_str(ctx.label) + ": invalid value '" + value + "'. Allowed values are " + str(allowed_values))
    return BuildSettingInfo(value = actual_values)

repeatable_string_flag = rule(
    implementation = _repeatable_string_flag_impl,
    build_setting = config.string(flag = True, allow_multiple = True),
    attrs = {
        "values": attr.string_list(
            doc = "The list of allowed values for this setting. An error is raised if any other value is given.",
        ),
    },
    doc = "A string-typed build setting that can be set on the command line",
)

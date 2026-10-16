// Copyright 2026 LocoDev. All Rights Reserved.
//
// Wingman ships precompiled: binaries only, no C++ source. This rules stub
// exists so C++ projects can build with the plugin enabled. UnrealBuildTool
// requires a module definition for every enabled code plugin, and
// bUsePrecompiled tells it to use the shipped binaries instead of compiling.

using UnrealBuildTool;

public class Wingman : ModuleRules
{
	public Wingman(ReadOnlyTargetRules Target) : base(Target)
	{
		bUsePrecompiled = true;
	}
}

//
//  SUBinaryDeltaCommon.h
//  Sparkle
//
//  Created by Mark Rowe on 2009-06-01.
//  Copyright 2009 Mark Rowe. All rights reserved.
//

#ifndef SUBINARYDELTACOMMON_H
#define SUBINARYDELTACOMMON_H

#include <fts.h>

#define PERMISSION_FLAGS (S_IRWXU | S_IRWXG | S_IRWXO | S_ISUID | S_ISGID | S_ISVTX)

#define IS_VALID_PERMISSIONS(mode) \
    (((mode & PERMISSION_FLAGS) == 0755) || ((mode & PERMISSION_FLAGS) == 0644))

#define BINARY_DELTA_ATTRIBUTES_KEY "binary-delta-attributes"
#define MAJOR_DIFF_VERSION_KEY "major-version"
#define MINOR_DIFF_VERSION_KEY "minor-version"
#define BEFORE_TREE_SHA1_KEY "before-tree-sha1"
#define AFTER_TREE_SHA1_KEY "after-tree-sha1"
#define DELETE_KEY "delete"
#define DELETE_THEN_EXTRACT_KEY "delete-then-extract"
#define BINARY_DELTA_KEY "binary-delta"
#define MODIFY_PERMISSIONS_KEY "mod-permissions"

// Properties no longer used in new patches
#define BEFORE_TREE_SHA1_OLD_KEY "before-sha1"
#define AFTER_TREE_SHA1_OLD_KEY "before-sha1"

#define MAJOR_VERSION_IS_AT_LEAST(actualMajor, expectedMajor) (actualMajor >= expectedMajor)

// Each major version will be assigned a name of a color
// Changes that break backwards compatibility will have different major versions
// Changes that affect creating but not applying patches will have different minor versions

typedef NS_ENUM(uint16_t, SUBinaryDeltaMajorVersion)
{
    SUAzureMajorVersion = 1,
    SUBeigeMajorVersion = 2
};

// Only keep track of the latest minor version for each major version
typedef NS_ENUM(uint16_t, SUBinaryDeltaMinorVersion)
{
    SUAzureMinorVersion = 0,
    SUBeigeMinorVersion = 0,
};

#define FIRST_DELTA_DIFF_MAJOR_VERSION SUAzureMajorVersion
#define FIRST_DELTA_DIFF_MINOR_VERSION SUAzureMinorVersion

#define LATEST_DELTA_DIFF_MAJOR_VERSION SUBeigeMajorVersion

@class NSString;
@class NSData;

extern int compareFiles(const FTSENT **a, const FTSENT **b);
extern NSData *hashOfFileContents(FTSENT *ent);
extern NSString *hashOfTreeWithVersion(NSString *path, uint16_t majorVersion);
extern NSString *hashOfTree(NSString *path);
extern BOOL removeTree(NSString *path);
extern BOOL copyTree(NSString *source, NSString *dest);
extern BOOL modifyPermissions(NSString *path, mode_t desiredPermissions);
extern NSString *pathRelativeToDirectory(NSString *directory, NSString *path);
NSString *temporaryFilename(NSString *base);
NSString *temporaryDirectory(NSString *base);
NSString *stringWithFileSystemRepresentation(const char*);
SUBinaryDeltaMinorVersion latestMinorVersionForMajorVersion(SUBinaryDeltaMajorVersion majorVersion);
#endif

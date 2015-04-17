//
//  SUBinaryDeltaApply.m
//  Sparkle
//
//  Created by Mark Rowe on 2009-06-01.
//  Copyright 2009 Mark Rowe. All rights reserved.
//

#import "SUBinaryDeltaApply.h"
#import "SUBinaryDeltaCommon.h"
#include <CommonCrypto/CommonDigest.h>
#import <Foundation/Foundation.h>
#include "bspatch.h"
#include <stdio.h>
#include <stdlib.h>
#include <xar/xar.h>

static BOOL applyBinaryDeltaToFile(xar_t x, xar_file_t file, NSString *sourceFilePath, NSString *destinationFilePath)
{
    NSString *patchFile = temporaryFilename(@"apply-binary-delta");
    xar_extract_tofile(x, file, [patchFile fileSystemRepresentation]);
    const char *argv[] = {"/usr/bin/bspatch", [sourceFilePath fileSystemRepresentation], [destinationFilePath fileSystemRepresentation], [patchFile fileSystemRepresentation]};
    BOOL success = (bspatch(4, (char **)argv) == 0);
    unlink([patchFile fileSystemRepresentation]);
    return success;
}

int applyBinaryDelta(NSString *source, NSString *destination, NSString *patchFile)
{
    xar_t x = xar_open([patchFile fileSystemRepresentation], READ);
    if (!x) {
        fprintf(stderr, "Unable to open %s. Giving up.\n", [patchFile fileSystemRepresentation]);
        return 1;
    }
    
    SUBinaryDeltaMajorVersion majorDiffVersion = FIRST_DELTA_DIFF_MAJOR_VERSION;
    SUBinaryDeltaMinorVersion minorDiffVersion = FIRST_DELTA_DIFF_MINOR_VERSION;

    NSString *expectedBeforeHashv1 = nil;
    NSString *expectedAfterHashv1 = nil;
    
    NSString *expectedNewBeforeHash = nil;
    NSString *expectedNewAfterHash = nil;
    
    xar_subdoc_t subdoc;
    for (subdoc = xar_subdoc_first(x); subdoc; subdoc = xar_subdoc_next(subdoc)) {
        if (!strcmp(xar_subdoc_name(subdoc), BINARY_DELTA_ATTRIBUTES_KEY)) {
            const char *value = 0;
            
            // available in version 2.0 or later
            xar_subdoc_prop_get(subdoc, MAJOR_DIFF_VERSION_KEY, &value);
            if (value)
                majorDiffVersion = (SUBinaryDeltaMajorVersion)[@(value) intValue];
            
            // available in version 2.0 or later
            xar_subdoc_prop_get(subdoc, MINOR_DIFF_VERSION_KEY, &value);
            if (value)
                minorDiffVersion = (SUBinaryDeltaMinorVersion)[@(value) intValue];
            
            // available in version 2.0 or later
            xar_subdoc_prop_get(subdoc, BEFORE_TREE_SHA1_KEY, &value);
            if (value)
                expectedNewBeforeHash = @(value);
            
            // available in version 2.0 or later
            xar_subdoc_prop_get(subdoc, AFTER_TREE_SHA1_KEY, &value);
            if (value)
                expectedNewAfterHash = @(value);
            
            // only available in version 1.0
            xar_subdoc_prop_get(subdoc, BEFORE_TREE_SHA1_OLD_KEY, &value);
            if (value)
                expectedBeforeHashv1 = @(value);
            
            // only available in version 1.0
            xar_subdoc_prop_get(subdoc, AFTER_TREE_SHA1_OLD_KEY, &value);
            if (value)
                expectedAfterHashv1 = @(value);
        }
    }
    
    if (majorDiffVersion < FIRST_DELTA_DIFF_MAJOR_VERSION) {
        fprintf(stderr, "Unable to identify diff-version %u in delta.  Giving up.\n", majorDiffVersion);
        return 1;
    }
    
    if (majorDiffVersion > LATEST_DELTA_DIFF_MAJOR_VERSION) {
        fprintf(stderr, "A later version is needed to apply this patch (on major version %u, but patch requests version %u).\n", LATEST_DELTA_DIFF_MAJOR_VERSION, majorDiffVersion);
        return 1;
    }
    
    BOOL usesNewTreeHash = MAJOR_VERSION_IS_AT_LEAST(majorDiffVersion, SUBeigeMajorVersion);
    
    NSString *expectedBeforeHash = usesNewTreeHash ? expectedNewBeforeHash : expectedBeforeHashv1;
    NSString *expectedAfterHash = usesNewTreeHash ? expectedNewAfterHash : expectedAfterHashv1;

    if (!expectedBeforeHash || !expectedAfterHash) {
        fprintf(stderr, "Unable to find before-sha1 or after-sha1 metadata in delta.  Giving up.\n");
        return 1;
    }

    fprintf(stdout, "Verifying source...  ");
    NSString *beforeHash = hashOfTreeWithVersion(source, majorDiffVersion);
    if (!beforeHash) {
        fprintf(stderr, "Unable to calculate hash of tree %s\n", [source fileSystemRepresentation]);
        return 1;
    }

    if (![beforeHash isEqualToString:expectedBeforeHash]) {
        fprintf(stderr, "Source doesn't have expected hash (%s != %s).  Giving up.\n", [expectedBeforeHash UTF8String], [beforeHash UTF8String]);
        return 1;
    }

    fprintf(stdout, "\nCopying files...  ");
    if (!removeTree(destination)) {
        fprintf(stderr, "Failed to remove %s\n", [destination fileSystemRepresentation]);
        return 1;
    }
    if (!copyTree(source, destination)) {
        fprintf(stderr, "Failed to copy %s to %s\n", [source fileSystemRepresentation], [destination fileSystemRepresentation]);
        return 1;
    }

    fprintf(stdout, "\nPatching... ");
    xar_file_t file;
    xar_iter_t iter = xar_iter_new();
    for (file = xar_file_first(x, iter); file; file = xar_file_next(iter)) {
        NSString *path = @(xar_get_path(file));
        NSString *sourceFilePath = [source stringByAppendingPathComponent:path];
        NSString *destinationFilePath = [destination stringByAppendingPathComponent:path];

        const char *value;
        if (!xar_prop_get(file, DELETE_KEY, &value) || !xar_prop_get(file, DELETE_THEN_EXTRACT_KEY, &value)) {
            if (!removeTree(destinationFilePath)) {
                fprintf(stderr, "%s or %s: failed to remove %s\n", DELETE_KEY, DELETE_THEN_EXTRACT_KEY, [destination fileSystemRepresentation]);
                return 1;
            }
            if (!xar_prop_get(file, DELETE_KEY, &value))
                continue;
        }

        if (!xar_prop_get(file, BINARY_DELTA_KEY, &value)) {
            if (!applyBinaryDeltaToFile(x, file, sourceFilePath, destinationFilePath)) {
                fprintf(stderr, "Unable to patch %s to destination %s\n", [sourceFilePath fileSystemRepresentation], [destinationFilePath fileSystemRepresentation]);
                return 1;
            }
        } else if (xar_prop_get(file, MODIFY_PERMISSIONS_KEY, &value)) {
            if (xar_extract_tofile(x, file, [destinationFilePath fileSystemRepresentation]) != 0) {
                fprintf(stderr, "Unable to extract file to %s\n", [destinationFilePath fileSystemRepresentation]);
                return 1;
            }
        }
        
        if (!xar_prop_get(file, MODIFY_PERMISSIONS_KEY, &value)) {
            if (!modifyPermissions(destinationFilePath, (mode_t)[[NSString stringWithUTF8String:value] intValue])) {
                fprintf(stderr, "Unable to modify permissions (%s) on file %s\n", value, [destinationFilePath fileSystemRepresentation]);
                return 1;
            }
        }
    }
    xar_close(x);

    fprintf(stdout, "\nVerifying destination...  ");
    NSString *afterHash = hashOfTreeWithVersion(destination, majorDiffVersion);
    if (!afterHash) {
        fprintf(stderr, "Unable to calculate hash of tree %s\n", [destination fileSystemRepresentation]);
        return 1;
    }

    if (![afterHash isEqualToString:expectedAfterHash]) {
        fprintf(stderr, "Destination doesn't have expected hash (%s != %s).  Giving up.\n", [expectedAfterHash UTF8String], [afterHash UTF8String]);
        removeTree(destination);
        return 1;
    }

    fprintf(stdout, "\nDone!\n");
    return 0;
}

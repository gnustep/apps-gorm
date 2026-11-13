/* GormDocumentIO.m
 *
 * Shared document file operations.
 *
 * Copyright (C) 2026 Free Software Foundation, Inc.
 *
 * This file is part of GNUstep.
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import "GormDocumentIO.h"
#import "GormDocument.h"

static void GormDocumentIOError(NSError **error, NSInteger code,
                              NSString *path, NSString *description)
{
  if (error != NULL)
    {
      NSMutableDictionary *info = [NSMutableDictionary dictionary];
      [info setObject: description forKey: NSLocalizedDescriptionKey];
      if (path != nil)
        {
          [info setObject: path forKey: NSFilePathErrorKey];
        }
      *error = [NSError errorWithDomain: NSCocoaErrorDomain
                                  code: code userInfo: info];
    }
}

@implementation GormDocumentIO
+ (GormDocument *) readDocumentFromFile: (NSString *)path
                               ofType: (NSString *)type
                               policy: (id<GormDocumentPolicy>)policy
                                error: (NSError **)error
{
  GormDocument * volatile document = nil;
  volatile BOOL loaded = NO;
  if (error != NULL) *error = nil;
  if ([path length] == 0 || [type length] == 0)
    {
      GormDocumentIOError(error, NSFileReadUnknownError, path,
                          @"A document path and type are required.");
      return nil;
    }

  NS_DURING
    {
      document = [[GormDocument alloc] initWithDocumentPolicy: policy];
      [document setFileType: type];
      [document setFileName: path];
      loaded = [document readFromFile: path ofType: type];
      if (!loaded)
        {
          GormDocumentIOError(error, NSFileReadUnknownError, path,
                              @"Could not load document.");
        }
    }
  NS_HANDLER
    {
      GormDocumentIOError(error, NSFileReadUnknownError, path,
                          [localException reason]);
    }
  NS_ENDHANDLER;
  if (loaded)
    {
      return AUTORELEASE(document);
    }
  RELEASE(document);
  return nil;
}

+ (BOOL) writeDocument: (GormDocument *)document
               toFile: (NSString *)path
               ofType: (NSString *)type
                error: (NSError **)error
{
  volatile BOOL saved = NO;
  if (error != NULL) *error = nil;
  if (document == nil || [path length] == 0 || [type length] == 0)
    {
      GormDocumentIOError(error, NSFileWriteUnknownError, path,
                          @"A document, path and type are required.");
      return NO;
    }

  NS_DURING
    {
      BOOL isDirectory = ([type isEqualToString: @"GSGormFileType"]
                          || [type isEqualToString: @"GSNibFileType"]
                          || [type isEqualToString: @"GSCodeFileType"]);
      if (isDirectory)
        {
          NSURL *url = [NSURL fileURLWithPath: path isDirectory: YES];
          saved = [document saveToURL: url ofType: type
                    forSaveOperation: NSSaveOperation error: error];
        }
      else
        {
          NSFileWrapper *wrapper = [document fileWrapperRepresentationOfType: type];
          if ([wrapper isRegularFile])
            {
              saved = [[wrapper regularFileContents] writeToFile: path
                                                      atomically: YES];
            }
        }
      if (!saved && (error == NULL || *error == nil))
        {
          GormDocumentIOError(error, NSFileWriteUnknownError, path,
                              @"Could not save document.");
        }
    }
  NS_HANDLER
    {
      GormDocumentIOError(error, NSFileWriteUnknownError, path,
                          [localException reason]);
    }
  NS_ENDHANDLER;
  return saved;
}
@end

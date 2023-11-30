//
//  FileStationError.swift
//
//  Copyright © 2023 Jaesung Jung. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

// MARK: - FileStationError

public class FileStationError: DiskStationError {
  public override var errorDescription: String? {
    switch code {
      // Common
    case 400:
      return "Invalid parameter of file operation"
    case 401:
      return "Unknown error of file operation"
    case 402:
      return "System is too busy"
    case 403:
      return "Invalid user does this file operation"
    case 404:
      return "Invalid group does this file operation"
    case 405:
      return "Invalid user and group does this file operation"
    case 406:
      return "Can't get user/group information from the account server"
    case 407:
      return "Operation not permitted"
    case 408:
      return "No such file or directory"
    case 409:
      return "Non-supported file system"
    case 410:
      return "Failed to connect internet-based file system (e.g., CIFS)"
    case 411:
      return "Read-only file system"
    case 412:
      return "Filename too long in the non-encrypted file system"
    case 413:
      return "Filename too long in the encrypted file system"
    case 414:
      return "File already exists"
    case 415:
      return "Disk quota exceeded"
    case 416:
      return "No space left on device"
    case 417:
      return "Input/output error"
    case 418:
      return "Illegal name or path"
    case 419:
      return "Illegal file name"
    case 420:
      return "Illegal file name on FAT file system"
    case 421:
      return "Device or resource busy"
    case 599:
      return "No such task of the file operation"
      // SYNO.FileStation.Favorite
    case 800:
      return "A folder path of favorite folder is already added to user's favorites"
    case 801:
      return "A name of favorite folder conflicts with an existing folder path in the user's favorites"
    case 802:
      return "There are too many favorites to be added"
      // SYNO.FileStation.Delete
    case 900:
      return "Failed to delete file(s)/folder(s)"
      // SYNO.FileStation.CopyMove
    case 1000:
      return "Failed to copy files/folders"
    case 1001:
      return "Failed to move files/folders"
    case 1002:
      return "An error occurred at the destination"
    case 1003:
      return "Cannot overwrite or skip the existing file because no overwrite parameter is given."
    case 1004:
      return "File cannot overwrite a folder with the same name, or folder cannot overwrite a file with the same name"
    case 1006:
      return "Cannot copy/move file/folder with special characters to a FAT32 file system"
    case 1007:
      return "Cannot copy/move a file bigger than 4G to a FAT32 file system"
      // SYNO.FileStation.CreateFolder
    case 1100:
      return "Failed to create a folder"
    case 1101:
      return "The number of folders to the parent folder would exceed the system limitation"
      // SYNO.FileStation.Rename
    case 1200:
      return "Failed to rename it"
      // SYNO.FileStation.Compress
    case 1300:
      return "Failed to compress files/folders"
    case 1301:
      return "Cannot create the archive because the given archive name is too long"
      // SYNO.FileStation.Extract
    case 1400:
      return "Failed to extract files"
    case 14001:
      return "Cannot open the file as archive"
    case 1402:
      return "Failed to read archive data error"
    case 1403:
      return "Wrong password"
    case 1404:
      return "Failed to get the file and dir list in an archive"
    case 1405:
      return "Failed to find the item ID in an archive file"
      // SYNO.FileStation.Upload
    case 1800:
      return "There is no Content-Length information in the HTTP header or the received size doesn't match the value of Content-Length information in the HTTP header"
    case 1801:
      return "Wait too long, no date can be received from client (Default maximum wait time is 3600 seconds)"
    case 1802:
      return "No filename information in the last part of file content"
    case 1803:
      return "Upload connection is cancelled"
    case 1804:
      return "Failed to upload oversized file to FAT file system"
    case 1805:
      return "Can't overwrite or skip the existing file, if no   parameter is given"
      // SYNO.FileStation.Sharing
    case 2000:
      return "Sharing link does not exist"
    case 2001:
      return "Cannot generate sharing link because too many sharing links exist"
    case 2002:
      return "Failed to access sharing links"
    default:
      return super.errorDescription
    }
  }
}

// MARK: - FileStationError (Static)

extension FileStationError {
  /// Invalid parameter of file operation
  public static let invalidFileOperationParameter = FileStationError(code: 400)

  /// Unknown error of file operation
  public static let unknownFileOperationError = FileStationError(code: 401)

  /// System is too busy
  public static let systemIsTooBusy = FileStationError(code: 402)

  /// Invalid user does this file operation
  public static let invalidUserFileOperation = FileStationError(code: 403)

  /// Invalid group does this file operation
  public static let invalidGroupFileOperation = FileStationError(code: 404)

  /// Invalid user and group does this file operation
  public static let invalidUserAndGroupFileOperation = FileStationError(code: 405)

  /// Can't get user/group information from the account server
  public static let userGroupInfoRetrieval = FileStationError(code: 406)

  /// Operation not permitted
  public static let operationNotPermitted = FileStationError(code: 407)

  /// No such file or directory
  public static let noSuchFileOrDirectory = FileStationError(code: 408)

  /// Non-supported file system
  public static let nonSupportedFileSystem = FileStationError(code: 409)

  /// Failed to connect internet-based file system (e.g., CIFS)
  public static let internetFileSystemConnection = FileStationError(code: 410)

  /// Read-only file system
  public static let readOnlyFileSystem = FileStationError(code: 411)

  /// Filename too long in the non-encrypted file system
  public static let filenameTooLongNonEncrypted = FileStationError(code: 412)

  /// Filename too long in the encrypted file system
  public static let filenameTooLongEncrypted = FileStationError(code: 413)

  /// File already exists
  public static let fileAlreadyExists = FileStationError(code: 414)

  /// Disk quota exceeded
  public static let diskQuotaExceeded = FileStationError(code: 415)

  /// No space left on device
  public static let noSpaceLeftOnDevice = FileStationError(code: 416)

  /// Input/output error
  public static let inputOutput = FileStationError(code: 417)

  /// Illegal name or path
  public static let illegalNameOrPath = FileStationError(code: 418)

  /// Illegal file name
  public static let illegalFileName = FileStationError(code: 419)

  /// Illegal file name on FAT file system
  public static let illegalFileNameFAT = FileStationError(code: 420)

  /// Device or resource busy
  public static let deviceResourceBusy = FileStationError(code: 421)

  /// No such task of the file operation
  public static let noSuchFileOperationTask = FileStationError(code: 599)

  /// A folder path of the favorite folder is already added to the user's favorites
  public static let favoriteFolderPathAlreadyAdded = FileStationError(code: 800)

  /// A name of the favorite folder conflicts with an existing folder path in the user's favorites
  public static let favoriteFolderNameConflict = FileStationError(code: 801)

  /// There are too many favorites to be added
  public static let tooManyFavoritesToAdd = FileStationError(code: 802)

  /// Failed to delete file(s)/folder(s)
  public static let failedToDeleteFilesOrFolders = FileStationError(code: 900)

  /// Failed to copy files/folders
  public static let failedToCopyFilesOrFolders = FileStationError(code: 1000)

  /// Failed to move files/folders
  public static let failedToMoveFilesOrFolders = FileStationError(code: 1001)

  /// An error occurred at the destination
  public static let errorAtDestination = FileStationError(code: 1002)

  /// Cannot overwrite or skip the existing file because no overwrite parameter is given.
  public static let noOverwriteParameter = FileStationError(code: 1003)

  /// File cannot overwrite a folder with the same name, or folder cannot overwrite a file with the same name
  public static let fileCannotOverwriteFolder = FileStationError(code: 1004)

  /// Cannot copy/move file/folder with special characters to a FAT32 file system
  public static let cannotCopyMoveSpecialCharsToFAT32 = FileStationError(code: 1006)

  /// Cannot copy/move a file bigger than 4G to a FAT32 file system
  public static let cannotCopyMoveFileBiggerThan4GToFAT32 = FileStationError(code: 1007)

  /// Failed to create a folder
  public static let failedToCreateFolder = FileStationError(code: 1100)

  /// The number of folders to the parent folder would exceed the system limitation
  public static let folderLimitExceeded = FileStationError(code: 1101)

  /// Failed to rename it
  public static let failedToRename = FileStationError(code: 1200)

  /// Failed to compress files/folders
  public static let failedToCompressFilesOrFolders = FileStationError(code: 1300)

  /// Cannot create the archive because the given archive name is too long
  public static let archiveNameTooLong = FileStationError(code: 1301)

  /// Failed to extract files
  public static let failedToExtractFiles = FileStationError(code: 1400)

  /// Cannot open the file as an archive
  public static let cannotOpenFileAsArchive = FileStationError(code: 14001)

  /// Failed to read archive data error
  public static let failedToReadArchiveData = FileStationError(code: 1402)

  /// Wrong password
  public static let wrongPassword = FileStationError(code: 1403)

  /// Failed to get the file and dir list in an archive
  public static let failedToGetFileAndDirListInArchive = FileStationError(code: 1404)

  /// Failed to find the item ID in an archive file
  public static let failedToFindItemIDInArchive = FileStationError(code: 1405)

  /// There is no Content-Length information in the HTTP header or the received size doesn't match the value of Content-Length information in the HTTP header
  public static let noContentLengthInformation = FileStationError(code: 1800)

  /// Wait too long, no date can be received from the client (Default maximum wait time is 3600 seconds)
  public static let uploadTimeout = FileStationError(code: 1801)

  /// No filename information in the last part of file content
  public static let noFilenameInformationInLastPart = FileStationError(code: 1802)

  /// Upload connection is cancelled
  public static let uploadConnectionCancelled = FileStationError(code: 1803)

  /// Failed to upload oversized file to FAT file system
  public static let failedToUploadOversizedFileToFAT = FileStationError(code: 1804)

  /// Can't overwrite or skip the existing file if no parameter is given
  public static let cantOverwriteOrSkipExistingFile = FileStationError(code: 1805)

  /// Sharing link does not exist
  public static let sharingLinkDoesNotExist = FileStationError(code: 2000)

  /// Cannot generate sharing link because too many sharing links exist
  public static let tooManySharingLinksExist = FileStationError(code: 2001)

  /// Failed to access sharing links
  public static let failedToAccessSharingLinks = FileStationError(code: 2002)
}

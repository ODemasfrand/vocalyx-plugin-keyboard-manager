package com.capanovi;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class ZippedKeyboardWriter{
	static final String IMAGES_FOLDER = "images";
	static final String SOUNDS_FOLDER = "sounds";

	private String filesDirectoryPath;
	private String tempDirectoryPath;
	private String keyboardName;
	private String zipName;

	private ZipOutputStream zipOutputStream;

	public ZippedKeyboardWriter(File externalFilesDirectory, File filesDirectory, String name) throws IOException{
		tempDirectoryPath = externalFilesDirectory.getAbsolutePath() + "/" + KeyboardsManager.APPLICATION_EXTERNAL_TEMP_FOLDER_NAME;
		cleanup();
		zipName = generateOutputFileName(name);
		FileOutputStream fileOutputStream = new FileOutputStream(tempDirectoryPath + "/" + zipName);
		zipOutputStream = new ZipOutputStream(new BufferedOutputStream(fileOutputStream));

		filesDirectoryPath = filesDirectory.getAbsolutePath();
		keyboardName = name;
	}

	public String getZipName(){
		return zipName;
	}

	public ZippedKeyboardWriter zip() throws IOException{
		String keyboardDirectoryPath = filesDirectoryPath + "/" + keyboardName;

		zipFilesFromDirectory(new File(keyboardDirectoryPath));

		List<File> files = getExtraFiles();

		for(File file : files)
			zipFile(file);

		zipOutputStream.close();
		return this;
	}

	private String generateOutputFileName(String fileName){
		SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd'_'HH-mm-ss");
		return fileName + "-" + simpleDateFormat.format(new Date()) + KeyboardsManager.ZIP_EXTENSION;
	}

	private ZippedKeyboardWriter cleanup(){
		File directory = new File(tempDirectoryPath);
		if (directory.exists())
			for(File f : directory.listFiles())
				f.delete();

		return this;
	}

	private void zipFilesFromDirectory(File source) throws IOException{
		File[] filesArray = source.listFiles();
		if(filesArray == null)
			return;

		List<File> files = new ArrayList<File>(Arrays.asList(filesArray));

		for(File file : files){
			if (file.isDirectory()){
				zipFilesFromDirectory(file);
				continue;
			}

			zipFile(file);
		}
	}

	private void zipFile(File file) throws IOException{
		String entryPath = getEntryPath(file);
		byte data[] = new byte[KeyboardsManager.WRITE_BUFFER_SIZE];

		FileInputStream fileInputStream = new FileInputStream(file.getAbsolutePath());
		BufferedInputStream bufferedInputStream = new BufferedInputStream(fileInputStream, KeyboardsManager.WRITE_BUFFER_SIZE);
		ZipEntry entry = new ZipEntry(entryPath);

		zipOutputStream.putNextEntry(entry);

		int readBytes;
		while((readBytes = bufferedInputStream.read(data, 0, KeyboardsManager.WRITE_BUFFER_SIZE)) != -1)
			zipOutputStream.write(data, 0, readBytes);

		bufferedInputStream.close();
		fileInputStream.close();
		zipOutputStream.closeEntry();
	}

	private String getEntryPath(File file){
		String filePath = file.getAbsolutePath();
		if (isImagesDirectoryPath(filePath))
			return trimPath(filePath, IMAGES_FOLDER);
		else if (isSoundsDirectoryPath(filePath))
			return trimPath(filePath, SOUNDS_FOLDER);

		return trimPath(filePath, keyboardName);
	}

	private String trimPath(String path, String string){
		String trimmed = path.substring(path.indexOf(string) + string.length());
		if (trimmed.isEmpty())
			throw new NullPointerException();

		return trimmed;
	}

	private boolean isSoundsDirectoryPath(String path){
		return path.contains(SOUNDS_FOLDER);
	}

	private boolean isImagesDirectoryPath(String path){
		return path.contains(IMAGES_FOLDER);
	}


	private List<File> getExtraFiles(){
		List<File> filesPaths = new ArrayList<File>();
		String tempDirectoryPath = filesDirectoryPath + "/" + KeyboardsManager.APPLICATION_TEMP_FOLDER_NAME + '/' + keyboardName;

		File applicationTempDirectory = new File(tempDirectoryPath);
		File[] files = applicationTempDirectory.listFiles();

		for(File file : files){
			if (isExtraFile(file))
				filesPaths.add(file);
			if (file.getName().equals(KeyboardsManager.KEYBOARD_INDEX_FILE_NAME))
				filesPaths.add(file);
		}

		return filesPaths;

	}

	private boolean isExtraFile(File file){
		return file.getName().contains(KeyboardsManager.KEYBOARD_EXTRA_FILE_SUFFIX);
	}
}

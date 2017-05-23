package com.capanovi;

import android.content.res.AssetManager;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;

public class ZippedKeyboardInstaller{
	static final String IMAGES_FOLDER = "images";
	static final Pattern IMAGE_PREFIX_PATTERN = Pattern.compile("^/?image-", Pattern.CASE_INSENSITIVE);
	static final Pattern JPG_PATTERN = Pattern.compile("^[^\\.]+.jpg$", Pattern.CASE_INSENSITIVE);
	static final Pattern PNG_PATTERN = Pattern.compile("^[^\\.]+.png$", Pattern.CASE_INSENSITIVE);
	static final Pattern GIF_PATTERN = Pattern.compile("^[^\\.]+.gif$", Pattern.CASE_INSENSITIVE);

	static final String SOUNDS_FOLDER = "sounds";
	static final Pattern SOUND_PREFIX_PATTERN = Pattern.compile("^/?sound-", Pattern.CASE_INSENSITIVE);
	static final Pattern THREEGP_PATTERN = Pattern.compile("^[^\\.]+.3gp$", Pattern.CASE_INSENSITIVE);
	static final Pattern WAV_PATTERN = Pattern.compile("^[^\\.]+.wav$", Pattern.CASE_INSENSITIVE);
	static final Pattern MP3_PATTERN = Pattern.compile("^[^\\.]+.mp3$", Pattern.CASE_INSENSITIVE);

	private boolean disposed;
	private ZippedKeyboard zippedKeyboard;
	private String targetFolderPath;

	public ZippedKeyboardInstaller(File filesDirectory, String zipFileName, String targetFolderName) throws IOException{
		targetFolderPath = filesDirectory.getAbsolutePath() + '/' + targetFolderName;
		zippedKeyboard = new ZippedKeyboard(zipFileName);
	}

	public ZippedKeyboardInstaller installFromAssets(AssetManager assets) throws IOException{
		zippedKeyboard.createZipInputStreamForAssets(assets);
		return install();
	}

	public ZippedKeyboardInstaller installFromDirectory(String directoryPath) throws IOException{
		zippedKeyboard.createZipInputStreamForDirectory(directoryPath);
		return install();
	}

	private ZippedKeyboardInstaller install() throws IOException{
		if (disposed)
			return this;
		ZipEntry entry;
		createFolderStructure();
		while((entry = zippedKeyboard.zipInputStream.getNextEntry()) != null)
			extractEntry(entry);

		dispose();
		return this;
	}

	private void createFolderStructure() throws IOException{
		File imagesFolder = new File(targetFolderPath + '/' + IMAGES_FOLDER);
		File soundsFolder = new File(targetFolderPath + '/' + SOUNDS_FOLDER);

		if (!imagesFolder.exists() && !imagesFolder.mkdirs())
			throw new IOException("Unable to create folder" + imagesFolder.getAbsolutePath());

		if (!soundsFolder.exists() && !soundsFolder.mkdirs())
			throw new IOException("Unable to create folder" + soundsFolder.getAbsolutePath());
	}

	private void extractEntry(ZipEntry entry) throws IOException{
		String entryPath = trimOffZipNameFromPath(entry.getName());

		if (isImage(entryPath))
			extractEntryToFolder(entryPath, IMAGES_FOLDER);

		else if (isSound(entryPath))
			extractEntryToFolder(entryPath, SOUNDS_FOLDER);
	}

	private boolean isImage(String filePath){
		return JPG_PATTERN.matcher(filePath).find() || PNG_PATTERN.matcher(filePath).find() || GIF_PATTERN.matcher(filePath).find() || IMAGE_PREFIX_PATTERN.matcher(filePath).find();
	}

	private boolean isSound(String filePath){
		return WAV_PATTERN.matcher(filePath).find() || THREEGP_PATTERN.matcher(filePath).find() || MP3_PATTERN.matcher(filePath).find() || SOUND_PREFIX_PATTERN.matcher(filePath).find();
	}

	private void extractEntryToFolder(String entryPath, String folderName) throws IOException{
		String outputPath = targetFolderPath + '/' + folderName + '/' + entryPath;

		if(isNestedPath(entryPath)){
			File file = new File(targetFolderPath + '/' + folderName + '/' + trimFileName(entryPath));
			if(!file.exists())
				file.mkdirs();
		}

		FileOutputStream outputStream = new FileOutputStream(outputPath);
		byte[] buffer = new byte[KeyboardsManager.READ_BUFFER_SIZE];
		int readBytes;

		while((readBytes = zippedKeyboard.zipInputStream.read(buffer)) != -1)
			outputStream.write(buffer, 0, readBytes);
		outputStream.close();
	}

	private boolean isNestedPath(String path){
		return path.contains("/") && path.substring(0, path.lastIndexOf("/")).length() > 0;
	}

	private String trimOffZipNameFromPath(String path){
		String zipName = this.zippedKeyboard.zipFileName.substring(0, this.zippedKeyboard.zipFileName.lastIndexOf(KeyboardsManager.ZIP_EXTENSION));
		if(path.contains(zipName))
			return path.substring(path.indexOf(zipName) + zipName.length());
		return path;
	}

	private String trimFileName(String path){
		return path.substring(0, path.lastIndexOf("/"));
	}

	private void dispose() throws IOException{
		this.zippedKeyboard.dispose();
		disposed = true;
	}
}

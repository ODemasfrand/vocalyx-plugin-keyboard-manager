package com.capanovi;

import android.content.res.AssetManager;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipInputStream;

public class ZippedKeyboard {
	public String zipFileName;
	public ZipInputStream zipInputStream;
	private InputStream inputStream;

	public ZippedKeyboard(String zipFileName){
		this.zipFileName = zipFileName;
	}

	public void createZipInputStreamForAssets(AssetManager assets) throws IOException {
		String zipFilePath = KeyboardsManager.KEYBOARDS_DIRECTORY_PATH + '/' + zipFileName;

		inputStream = assets.open(zipFilePath);
		zipInputStream = new ZipInputStream(inputStream);
	}

	public void createZipInputStreamForDirectory(String directoryPath) throws IOException{
		String zipFilePath = directoryPath + '/' + zipFileName;
		inputStream = new FileInputStream(zipFilePath);
		zipInputStream = new ZipInputStream(inputStream);
	}

	public void dispose() throws IOException {
		inputStream.close();
		zipInputStream.close();
	}
}

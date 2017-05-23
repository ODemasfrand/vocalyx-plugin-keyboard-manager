package com.capanovi;

import android.content.res.AssetManager;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;

public class ZippedKeyboardParser{
	static final Pattern EXTRA_PATTERN = Pattern.compile("^[a-zA-Z].*\\.extra\\.json$", Pattern.CASE_INSENSITIVE);

	private boolean disposed = false;
	private ZippedKeyboard zippedKeyboard;

	private long uncompressedSize = 0;
	private StringBuilder indexBuilder;
	private List<String> extraPropertiesList;


	public ZippedKeyboardParser(String zipFileName) throws IOException{
		zippedKeyboard = new ZippedKeyboard(zipFileName);
		indexBuilder = new StringBuilder();
		extraPropertiesList = new ArrayList<String>();
	}

	public ZippedKeyboardParser readFromAssets(AssetManager assets) throws IOException{
		zippedKeyboard.createZipInputStreamForAssets(assets);
		return read();
	}

	public ZippedKeyboardParser readFromDirectory(String directoryPath) throws IOException{
		zippedKeyboard.createZipInputStreamForDirectory(directoryPath);
		return read();
	}

	private ZippedKeyboardParser read() throws IOException{
		ZipEntry entry;
		if (disposed)
			return this;

		while((entry = zippedKeyboard.zipInputStream.getNextEntry()) != null)
			if (isIndexFile(entry))
				readIndex();
			else if (isExtraFile(entry))
				readExtraFile();
			else
				skipEntry();
		dispose();
		return this;
	}

	private boolean isIndexFile(ZipEntry entry){
		String entryName = entry.getName().substring(entry.getName().lastIndexOf("/") + 1);
		return entryName.equals(KeyboardsManager.KEYBOARD_INDEX_FILE_NAME);
	}

	private boolean isExtraFile(ZipEntry entry){
		String entryName = entry.getName().substring(entry.getName().lastIndexOf("/") + 1);
		return EXTRA_PATTERN.matcher(entryName).find();
	}

	private void readIndex() throws IOException{
		byte[] buffer = new byte[KeyboardsManager.READ_BUFFER_SIZE];
		int readBytes;

		while((readBytes = zippedKeyboard.zipInputStream.read(buffer)) != -1){
			indexBuilder.append(new String(buffer, 0, readBytes));
			uncompressedSize += readBytes;
		}
	}

	private void readExtraFile() throws IOException{
		byte[] buffer = new byte[KeyboardsManager.READ_BUFFER_SIZE];
		int readBytes;

		while((readBytes = zippedKeyboard.zipInputStream.read(buffer)) != -1){
			extraPropertiesList.add(new String(buffer, 0, readBytes));
			uncompressedSize += readBytes;
		}
	}

	private void skipEntry() throws IOException{
		long skippedBytes;
		while((skippedBytes = zippedKeyboard.zipInputStream.skip(KeyboardsManager.SKIP_SIZE)) != 0)
			uncompressedSize += skippedBytes;
	}

	private void dispose() throws IOException{
		this.zippedKeyboard.dispose();
		this.disposed = true;
	}

	public JSONObject toJSON() throws JSONException{
		JSONObject keyboardJSON = new JSONObject();

		keyboardJSON.put(KeyboardsManager.KeyboardProperties.FILE_NAME.toString(), zippedKeyboard.zipFileName);
		keyboardJSON.put(KeyboardsManager.KeyboardProperties.INDEX_STRING.toString(), indexBuilder.toString());

		keyboardJSON.put(KeyboardsManager.KeyboardProperties.EXTRAS_STRING.toString(), createExtrasJson());
		keyboardJSON.put(KeyboardsManager.KeyboardProperties.UNCOMPRESSED_FILE_SIZE.toString(), uncompressedSize);

		return keyboardJSON;
	}

	private JSONObject createExtrasJson() throws JSONException{
		JSONObject mergedJson = new JSONObject();
		for(String json : extraPropertiesList){
			JSONObject jsonObject = new JSONObject(json);
			Iterator iterator = jsonObject.keys();

			while(iterator.hasNext()){
				String key = (String) iterator.next();
				mergedJson.put(key, jsonObject.get(key));
			}
		}

		return mergedJson;
	}
}

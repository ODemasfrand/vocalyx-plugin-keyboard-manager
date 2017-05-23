package com.capanovi;

import android.content.res.AssetManager;
import android.os.Environment;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.File;
import java.io.FileNotFoundException;

public class KeyboardsManager extends CordovaPlugin{
	static private final String MISSING_KEYBOARD_MESSAGE = "MISSING_KEYBOARD";
	static private final int ONE_MEGABYTE = 1024 * 1024 * 1024;

	static final String KEYBOARDS_DIRECTORY_PATH = "www/assets/keyboards";
	static final String APPLICATION_TEMP_FOLDER_NAME = "temp";
	static final String APPLICATION_EXTERNAL_TEMP_FOLDER_NAME = "temp";
	static final String KEYBOARD_INDEX_FILE_NAME = "index.csv";
	static final String KEYBOARD_EXTRA_FILE_SUFFIX = "extra.json";
	static final String ZIP_EXTENSION = ".zip";

	static final int READ_BUFFER_SIZE = 8192;
	static final int WRITE_BUFFER_SIZE = 8192;
	static final int SKIP_SIZE = ONE_MEGABYTE;

	private AssetManager assets;
	private File filesDirectory;
	private File externalFilesDirectory;

	public KeyboardsManager(){
	}

	public void initialize(CordovaInterface cordova, CordovaWebView webView){
		super.initialize(cordova, webView);
		assets = cordova.getActivity().getAssets();
		filesDirectory = cordova.getActivity().getFilesDir();
		externalFilesDirectory = cordova.getActivity().getExternalFilesDir(null);
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext){
		if (action.equals("listEmbeddedKeyboards"))
			return listEmbeddedKeyboards(callbackContext);
		if (action.equals("installEmbedded"))
			return installEmbeddedKeyboard(args, callbackContext);
		if (action.equals("install"))
			return installKeyboard(args, callbackContext);
		if (action.equals("getFolderSize"))
			return getFolderSize(args, callbackContext);
		if (action.equals("zipKeyboard"))
			return zipKeyboard(args, callbackContext);
		if (action.equals("parseKeyboardZip"))
			return parseKeyboardZip(args, callbackContext);
		return false;
	}

	private boolean listEmbeddedKeyboards(final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					String[] keyboardsFileNames = assets.list(KEYBOARDS_DIRECTORY_PATH);
					JSONArray keyboardsJSON = new JSONArray();

					for(String keyboardFileName : keyboardsFileNames)
						keyboardsJSON.put(new ZippedKeyboardParser(keyboardFileName)
							.readFromAssets(assets)
							.toJSON());

					callbackContext.success(keyboardsJSON);
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}
		});
		return true;
	}

	private boolean installEmbeddedKeyboard(final JSONArray args, final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					String zipFileName = args.getString(0);
					String targetFolderName = args.getString(1);
					new ZippedKeyboardInstaller(filesDirectory, zipFileName, targetFolderName)
						.installFromAssets(assets);
					callbackContext.success();
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}
		});
		return true;
	}

	private boolean installKeyboard(final JSONArray args, final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					String zipFileName = args.getString(0);
					String targetFolderName = args.getString(1);
					new ZippedKeyboardInstaller(filesDirectory, zipFileName, targetFolderName)
						.installFromDirectory(filesDirectory.getAbsolutePath() + "/" + APPLICATION_TEMP_FOLDER_NAME);
					callbackContext.success();
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}
		});
		return true;
	}

	private boolean getFolderSize(final JSONArray args, final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					File directory = new File(filesDirectory.getAbsolutePath() + '/' + args.getString(0));
					JSONObject result = new JSONObject();
					result.put("size", folderSize(directory));

					callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, folderSize(directory)));
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}

			public long folderSize(File directory){
				if (!directory.exists())
					return 0;

				if (directory.isFile())
					return directory.length();

				long length = 0;
				for(File file : directory.listFiles())
					length += folderSize(file);

				return length;
			}
		});
		return true;
	}

	private boolean zipKeyboard(final JSONArray args, final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					String keyboardName = args.getString(0);
					ZippedKeyboardWriter zippedKeyboardWriter = new ZippedKeyboardWriter(externalFilesDirectory, filesDirectory, keyboardName);

					zippedKeyboardWriter.zip();

					callbackContext.success(zippedKeyboardWriter.getZipName());
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}
		});
		return true;
	}

	private boolean parseKeyboardZip(final JSONArray args, final CallbackContext callbackContext){
		cordova.getThreadPool().execute(new Runnable(){
			@Override
			public void run(){
				try{
					String keyboardFileName = args.getString(0) + ZIP_EXTENSION;
					String tempFolderPath = filesDirectory.getAbsolutePath() + "/" + APPLICATION_TEMP_FOLDER_NAME;

					JSONObject jsonObject = new ZippedKeyboardParser(keyboardFileName)
						.readFromDirectory(tempFolderPath)
						.toJSON();

					callbackContext.success(jsonObject);
				} catch(FileNotFoundException e){
					callbackContext.error(MISSING_KEYBOARD_MESSAGE);
				} catch(Exception e){
					callbackContext.error(e.getMessage());
				}
			}
		});
		return true;
	}

	enum KeyboardProperties{
		FILE_NAME("fileName"),
		UNCOMPRESSED_FILE_SIZE("uncompressedFileSize"),
		INDEX_STRING("indexString"),
		EXTRAS_STRING("extras");

		private String value = "";

		KeyboardProperties(String value){
			this.value = value;
		}

		public String toString(){
			return value;
		}
	}
}

package fragments;

import android.app.AlertDialog;
import android.bluetooth.BluetoothGattCharacteristic;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Color;
import android.support.v4.app.Fragment;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.gttronics.ble.blelibrary.BleDevice;
import com.gttronics.ble.blelibrary.BleDeviceCallback;
import com.gttronics.ble.blelibrary.dataexchanger.DataExchangerProfile;
import com.gttronics.ble.blelibrary.dataexchanger.DataExchangerProfileCallback;
import com.gttronics.ble.blelibrary.dataexchanger.DataExchangerDevice;

import com.gttronics.ble.blelibrary.dataexchanger.DxAppController;

/**
 * Created by EGUSI16 on 11/22/2016.
 */

public abstract class DxAppFragment extends Fragment implements BleDeviceCallback, DataExchangerProfileCallback{

    protected DxAppController dxAppController;
    protected byte[] rxData;

    protected ImageView imageViewBLE;
    protected EditText editTextRx;
    protected EditText editTextTx;
    protected TextView textViewRx;
    protected TextView textViewTx;
    protected ScrollView scrollViewRx;
    protected View disconnectBtn;
    protected TextView hexBtn;
    protected RelativeLayout header;

    public boolean startBle() {
        dxAppController = DxAppController.getInstance(getActivity().getApplicationContext());

        // alert user if BLE is supported by device
        if (!dxAppController.isBleSupport()) {
            new AlertDialog.Builder(getActivity())
                    .setMessage("BLE not supported by this device.")
                    .setTitle("Data Exchanger")
                    .setNeutralButton(android.R.string.cancel,
                            new DialogInterface.OnClickListener() {
                                public void onClick(DialogInterface dialog, int whichButton){
                                    int pid = android.os.Process.myPid();
                                    android.os.Process.killProcess(pid);
                                    System.exit(0);
                                }
                            }
                    ).show();

            return false;
        }

        // alert user if BLE is not enabled
        if (!dxAppController.isBluetoothEnabled()){
            new AlertDialog.Builder(getActivity())
                    .setMessage("Bluetooth is disabled. Press OK to enable.")
                    .setTitle("Data Exchanger")
                    .setPositiveButton(android.R.string.cancel,
                            new DialogInterface.OnClickListener() {
                                public void onClick(DialogInterface dialog, int whichButton){
                                    int pid = android.os.Process.myPid();
                                    android.os.Process.killProcess(pid);
                                    System.exit(0);
                                }
                            }
                    )
                    .setNegativeButton(android.R.string.ok,
                            new DialogInterface.OnClickListener() {
                                public void onClick(DialogInterface dialog, int whichButton){
                                    Intent intentOpenBluetoothSettings = new Intent();
                                    intentOpenBluetoothSettings.setAction(android.provider.Settings.ACTION_BLUETOOTH_SETTINGS);
                                    startActivity(intentOpenBluetoothSettings);
                                }
                            }
                    )
                    .show();

            return false;
        }

//        dxDev = new DataExchangerDevice(getActivity().getApplicationContext(), this);

        // Create DataExchanger profile
        // - required callback functions are:
        //   1/ onRxDataAvailable - called when data is sent from the connected BLE device
        // - use dxProfile.sendData() function to send data
//        dxProfile = new DataExchangerProfile(dxDev, dxAppController);

//        dxProfile.reset();

        // Assign profile to device
        //dxDev.registerProfile(dxProfile);

        // Assign device to controller
        //dxAppController.registerDevice(dxDev);
        dxAppController.setDataReceiveCallback(this);
        dxAppController.setBleController(this);

        return true;
    }

    @Override
    public void onDeviceStateChanged(BleDevice dev, BLE_DEV_STATE state)
    {
        Log.d("MAIN", "State:" + state);

        // Device is discovered and connected but its service has not been discovered
        if( state == BLE_DEV_STATE.CONNECTED_NOT_SVC_RDY )
        {
            getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    editTextRx.setText("Device Found");

                    editTextTx.setVisibility(View.GONE);
                    //textViewTx.setVisibility(View.GONE);
                }
            });

            // Stop discovery scan if a device is connected
            dxAppController.stopScan();
        }

        // Device is disconnected
        else if( state == BLE_DEV_STATE.DISCONNECTED )
        {
            getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    editTextRx.setText("Searching for devices ...");

                    editTextTx.setVisibility(View.GONE);
                    //textViewTx.setVisibility(View.GONE);
                }
            });

            // Re-enable device discovery
            // - ready to connect to a new device.
            dxAppController.startScan();
        }
    }

    @Override
    public void onAllProfilesReady(BleDevice dev, boolean isAllReady)
    {
        if( isAllReady )
        {
            // App is ready to interact with the BLE device.
            // - place your code here to start working with the device
            //
            getActivity().runOnUiThread(new Runnable() {
                public void run() {
                    imageViewBLE.setColorFilter(Color.rgb(255,165,0));
                    editTextRx.setText("");

                    editTextTx.setVisibility(View.VISIBLE);
                }
            });

            Log.d("MAIN", "All profiles are ready.");
        }
        else
        {
            // If not ready, do some error handling here
            Log.d("MAIN", "Not all profiles are ready.");
            dev.close();
        }
    }

    @Override
    public void onRxDataAvailable(BleDevice dev, byte[] data)
    {
        Log.d(TAG, "Rx data available: " + new String(data));
        rxData = data;

//        // Place your code here to handle the received data
//        //
//
//        getActivity().runOnUiThread(new Runnable() {
//            public void run() {
//                Date currentLocalTime = Calendar.getInstance().getTime();
//                SimpleDateFormat simpleDateFormat = new java.text.SimpleDateFormat("mm::ss::SSS");
//                String formattedCurrentDate = simpleDateFormat.format(currentLocalTime);
//
//                String rxString = formattedCurrentDate + ":" + new String(rxData) + "\n" + editTextRx.getText().toString();
//
//                editTextRx.setText(rxString);
//                Log.d("MAIN", "Rx Data [" + new String(rxData) +"]");
//            }
//        });

    }

    @Override
    public void onRx2DataAvailable(BleDevice dev, byte[] data) {
        Log.d(TAG, "Rx 2 data available: " + new String(data));

        rxData = data;
    }

    @Override
    public void onTxCreditDataAvailable(BleDevice dev, byte[] data) {
        Log.d(TAG, "Tx credit data available: " + new String(data));

        rxData = data;
    }

    @Override
    public void onUpdateValueForCharacteristic(BluetoothGattCharacteristic c) {
        Log.d(TAG, "onUpdateValueForCharacteristic: " + new String(c.getValue()));
    }

    @Override
    public void onCharacteristicWrite(BluetoothGattCharacteristic c) {
        Log.d(TAG, "onCharacteristicWrite: " + new String(c.getValue()));
    }


}

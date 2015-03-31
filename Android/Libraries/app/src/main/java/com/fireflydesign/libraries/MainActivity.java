package com.fireflydesign.libraries;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;

import com.fireflydesign.fireflydevice.FDFireflyIce;
import com.fireflydesign.fireflydevice.FDFireflyIceChannelBLE;
import com.fireflydesign.fireflydevice.FDFireflyIceManager;

import java.util.UUID;

public class MainActivity extends Activity implements FDFireflyIceManager.Delegate {

    FDFireflyIceManager fireflyIceManager;
    BluetoothDevice bluetoothDevice;
    FDFireflyIce fireflyIce;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        UUID serviceUUID = UUID.fromString("310a0001-1b95-5091-b0bd-b7a681846399"); // Firefly Ice
        BluetoothManager bluetoothManager = (BluetoothManager)getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();
        if (bluetoothAdapter != null) {
            fireflyIceManager = new FDFireflyIceManager(bluetoothAdapter, serviceUUID, this);
            fireflyIceManager.setDiscovery(true);
        }
    }

    public void discovered(FDFireflyIceManager manager, BluetoothDevice device) {
        if (bluetoothDevice != null) {
            return;
        }

        bluetoothDevice = device;
        fireflyIce = new FDFireflyIce();
        FDFireflyIceChannelBLE channel = new FDFireflyIceChannelBLE(this, bluetoothDevice);
        fireflyIce.addChannel(channel, "BLE");
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }
}

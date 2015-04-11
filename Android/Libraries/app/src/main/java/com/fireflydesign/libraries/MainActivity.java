package com.fireflydesign.libraries;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.os.Bundle;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.CheckBox;
import android.widget.ListView;
import android.widget.TextView;

import com.fireflydesign.fireflydevice.FDFireflyIce;
import com.fireflydesign.fireflydevice.FDFireflyIceChannelBLE;
import com.fireflydesign.fireflydevice.FDFireflyIceManager;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public class MainActivity extends Activity implements FDFireflyIceManager.Delegate {

    FDFireflyIceManager fireflyIceManager;
    Map<String, Map<String, Object>> discovered;
    List<String> listViewItems;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        discovered = new HashMap<>();
        listViewItems = new ArrayList<String>();
        ListView listView = (ListView)findViewById(R.id.listView);
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_single_choice, listViewItems);
        listView.setAdapter(adapter);

        UUID serviceUUID = UUID.fromString("310a0001-1b95-5091-b0bd-b7a681846399"); // Firefly Ice
        BluetoothManager bluetoothManager = (BluetoothManager)getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();
        if (bluetoothAdapter != null) {
            fireflyIceManager = new FDFireflyIceManager(bluetoothAdapter, serviceUUID, this);
        } else {
            TextView statusTextView = (TextView)findViewById(R.id.statusTextView);
            statusTextView.setText("Bluetooth is not available!");
        }
    }

    public void discovered(FDFireflyIceManager manager, BluetoothDevice bluetoothDevice) {
        Map map = discovered.get(bluetoothDevice.getAddress());
        if (map != null) {
            return;
        }

        FDFireflyIce fireflyIce = new FDFireflyIce();
        FDFireflyIceChannelBLE channel = new FDFireflyIceChannelBLE(this, bluetoothDevice);
        fireflyIce.addChannel(channel, "BLE");

        map = new HashMap();
        map.put("bluetoothDevice", bluetoothDevice);
        map.put("fireflyIce", fireflyIce);
        discovered.put(bluetoothDevice.getAddress(), map);

        // add to end of list
        ListView listView = (ListView)findViewById(R.id.listView);
        ArrayAdapter<String> adapter = (ArrayAdapter<String>)listView.getAdapter();
        adapter.add(bluetoothDevice.getAddress());
    }

    public void onScanCheckBoxChange(View view) {
        CheckBox checkBox = (CheckBox)view;
        fireflyIceManager.setDiscovery(checkBox.isChecked());
    }

    public void onConnectButtonClicked(View view) {
        ListView listView = (ListView)findViewById(R.id.listView);
        int position = listView.getCheckedItemPosition();
        String address = listViewItems.get(position);
        Map map = discovered.get(address);
        FDFireflyIce fireflyIce = (FDFireflyIce)map.get("fireflyIce");
        FDFireflyIceChannelBLE channel = (FDFireflyIceChannelBLE)fireflyIce.channels.get("BLE");
        channel.open();
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

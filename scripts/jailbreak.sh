#!/usr/bin/sudo bash
set -ex

VOLBASE='/mnt'
USRBASE="${VOLBASE}/Users/ec2-user"

mount -o readwrite /dev/xvdf2 "${VOLBASE}"

/usr/bin/sqlite3 "${VOLBASE}/private/var/db/SystemPolicyConfiguration/KextPolicy" << EOF
	CREATE TRIGGER IF NOT EXISTS INSERT_OF_allowed_ON_kext_policy AFTER INSERT ON kext_policy FOR EACH ROW WHEN NEW.allowed != 1
	BEGIN
		UPDATE kext_policy SET allowed = 1 WHERE team_id = NEW.team_id AND bundle_id = NEW.bundle_id;
	END;

	CREATE TRIGGER IF NOT EXISTS UPDATE_OF_allowed_ON_kext_policy AFTER UPDATE OF allowed ON kext_policy FOR EACH ROW WHEN NEW.allowed != 1
	BEGIN
		UPDATE kext_policy SET allowed = 1 WHERE team_id = NEW.team_id AND bundle_id = NEW.bundle_id;
	END;

	UPDATE kext_policy SET allowed = 1;

	CREATE TRIGGER IF NOT EXISTS INSERT_OF_flags_ON_kext_policy AFTER INSERT ON kext_policy FOR EACH ROW WHEN NEW.flags != 0
	BEGIN
		UPDATE kext_policy SET flags = 0 WHERE team_id = NEW.team_id AND bundle_id = NEW.bundle_id;
	END;

	CREATE TRIGGER IF NOT EXISTS UPDATE_OF_flags_ON_kext_policy AFTER UPDATE OF flags ON kext_policy FOR EACH ROW WHEN NEW.flags != 0
	BEGIN
		UPDATE kext_policy SET flags = 0 WHERE team_id = NEW.team_id AND bundle_id = NEW.bundle_id;
	END;

	UPDATE kext_policy SET flags = 0;

	CREATE TRIGGER IF NOT EXISTS INSERT_OF_flags_ON_kext_load_history_v3 AFTER INSERT ON kext_load_history_v3 FOR EACH ROW WHEN NEW.flags != 16
	BEGIN
		UPDATE kext_load_history_v3 SET flags = 16 WHERE path = NEW.path;
	END;

	CREATE TRIGGER IF NOT EXISTS UPDATE_OF_flags_ON_kext_load_history_v3 AFTER UPDATE OF flags ON kext_load_history_v3 FOR EACH ROW WHEN NEW.flags != 16
	BEGIN
		UPDATE kext_load_history_v3 SET flags = 16 WHERE path = NEW.path;
	END;
	
	UPDATE kext_load_history_v3 SET flags = 16;
EOF

TCC='/Library/Application Support/com.apple.TCC/TCC.db'
TCCVOL="${VOLBASE}${TCC}"
TCCUSR="${USRBASE}${TCC}"

# SERVICES=($(grep -aoE 'kTCCService\w+' "${VOLBASE}/System/Library/PrivateFrameworks/TCC.framework/Resources/tccd" | sed -E 's/^kTCCService//' | grep -v '^$' | sort | uniq))
SERVICES=('Accessibility' 'AddressBook' 'AppleEvents' 'BluetoothAlways' 'BluetoothPeripheral' 'BluetoothWhileInUse' 'Calendar' 'Calls' 'Camera' 'ContactsFull' 'ContactsLimited' 'DeveloperTool' 'ExposureNotificationRegion' 'Facebook' 'FallDetection' 'FileProviderDomain' 'FileProviderPresence' 'FocusStatus' 'GameCenterFriends' 'KeyboardNetwork' 'LinkedIn' 'ListenEvent' 'Liverpool' 'MSO' 'MediaLibrary' 'Microphone' 'Motion' 'NearbyInteraction' 'Photos' 'PhotosAdd' 'PostEvent' 'Prototype3Rights' 'Prototype4Rights' 'Reminders' 'ScreenCapture' 'SensorKitAmbientLightSensor' 'SensorKitBedSensing' 'SensorKitBedSensingWriting' 'SensorKitDeviceUsage' 'SensorKitElevation' 'SensorKitFacialMetrics' 'SensorKitForegroundAppCategory' 'SensorKitKeyboardMetrics' 'SensorKitLocationMetrics' 'SensorKitMessageUsage' 'SensorKitMotion' 'SensorKitMotionHeartRate' 'SensorKitOdometer' 'SensorKitPedometer' 'SensorKitPhoneUsage' 'SensorKitSoundDetection' 'SensorKitSpeechMetrics' 'SensorKitStrideCalibration' 'SensorKitWatchAmbientLightSensor' 'SensorKitWatchFallStats' 'SensorKitWatchForegroundAppCategory' 'SensorKitWatchHeartRate' 'SensorKitWatchMotion' 'SensorKitWatchOnWristState' 'SensorKitWatchPedometer' 'SensorKitWatchSpeechMetrics' 'ShareKit' 'SinaWeibo' 'Siri' 'SpeechRecognition' 'SystemPolicyAllFiles' 'SystemPolicyDesktopFolder' 'SystemPolicyDeveloperFiles' 'SystemPolicyDocumentsFolder' 'SystemPolicyDownloadsFolder' 'SystemPolicyNetworkVolumes' 'SystemPolicyRemovableVolumes' 'SystemPolicySysAdminFiles' 'TencentWeibo' 'Twitter' 'Ubiquity' 'UserAvailability' 'UserTracking' 'WebKitIntelligentTrackingPrevention' 'Willow')
CLIENTS0=('com.apple.CoreSimulator.SimulatorTrampoline' 'com.apple.dt.Xcode-Helper' 'com.apple.Terminal')
CLIENTS1=('/opt/aws/ssm/bin/amazon-ssm-agent' '/usr/libexec/sshd-keygen-wrapper')
OBJECTS0=('UNUSED' 'com.apple.finder' 'com.apple.systemevents')
OBJECTS1=()
{
	echo 'BEGIN EXCLUSIVE TRANSACTION;'
	for SERVICE in "${SERVICES[@]}"
	do
		for CLIENT in "${CLIENTS0[@]}"
		do
			for OBJECT in "${OBJECTS0[@]}"
			do
				echo "INSERT INTO access VALUES ('kTCCService${SERVICE}','${CLIENT}',0,2,4,1,NULL,NULL,0,'${OBJECT}',NULL,0,0);"
			done
			for OBJECT in "${OBJECTS1[@]}"
			do
				echo "INSERT INTO access VALUES ('kTCCService${SERVICE}','${CLIENT}',0,2,4,1,NULL,NULL,1,'${OBJECT}',NULL,0,0);"
			done
		done
		for CLIENT in "${CLIENTS1[@]}"
		do
			for OBJECT in "${OBJECTS0[@]}"
			do
				echo "INSERT INTO access VALUES ('kTCCService${SERVICE}','${CLIENT}',1,2,4,1,NULL,NULL,0,'${OBJECT}',NULL,0,0);"
			done
			for OBJECT in "${OBJECTS1[@]}"
			do
				echo "INSERT INTO access VALUES ('kTCCService${SERVICE}','${CLIENT}',1,2,4,1,NULL,NULL,1,'${OBJECT}',NULL,0,0);"
			done
		done
	done
	echo 'COMMIT TRANSACTION;'
} | /usr/bin/sqlite3 "${TCCVOL}"

mkdir -p "$(dirname "${TCCUSR}")"
/usr/bin/sqlite3 "${TCCVOL}" '.dump' | /usr/bin/sqlite3 "${TCCUSR}"
chown 501:20 "${TCCUSR}"

umount "${VOLBASE}"

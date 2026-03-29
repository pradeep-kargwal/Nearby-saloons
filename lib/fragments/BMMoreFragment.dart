import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../utils/BMBottomSheet.dart';
import '../utils/BMColors.dart';
import '../utils/BMConstants.dart';
import '../utils/BMWidgets.dart';

class BMMoreFragment extends StatefulWidget {
  const BMMoreFragment({Key? key}) : super(key: key);

  @override
  State<BMMoreFragment> createState() => _BMMoreFragmentState();
}

class _BMMoreFragmentState extends State<BMMoreFragment> {
  @override
  void initState() {
    setStatusBarColor(bmSpecialColor);
    super.initState();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStore.isDarkModeOn
          ? appStore.scaffoldBackground!
          : bmLightScaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          upperContainer(
            screenContext: context,
            child: Column(
              children: [
                40.height,
                titleText(title: 'Places Directory'),
                4.height,
                Text('Discover beauty services near you',
                    style: secondaryTextStyle(color: Colors.white70, size: 13)),
                16.height,
              ],
            ),
          ),
          lowerContainer(
            child: Column(
              children: [
                16.height,
                Row(
                  children: [
                    appStore.isDarkModeOn
                        ? Icon(Icons.brightness_2,
                            color: bmPrimaryColor, size: 24)
                        : Icon(Icons.wb_sunny_rounded,
                            color: bmPrimaryColor, size: 24),
                    16.width,
                    Text('Dark Mode',
                            style: boldTextStyle(
                                size: 16,
                                color: appStore.isDarkModeOn
                                    ? white
                                    : bmSpecialColorDark))
                        .expand(),
                    Switch(
                      value: appStore.isDarkModeOn,
                      activeTrackColor: bmSpecialColor,
                      inactiveThumbColor: bmPrimaryColor,
                      inactiveTrackColor: Colors.grey,
                      onChanged: (val) async {
                        appStore.toggleDarkMode(value: val);
                        await setValue(isDarkModeOnPref, val);
                      },
                    ),
                  ],
                ).paddingSymmetric(horizontal: 16, vertical: 8),
                Divider().paddingSymmetric(horizontal: 16),
                _buildSettingItem(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => showSelectStaffBottomSheet(context),
                ),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: 'About App',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.star_outline,
                  title: 'Rate Us',
                  subtitle: 'Share your experience',
                  onTap: () => _openUrl('https://play.google.com/store'),
                ),
                _buildSettingItem(
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  subtitle: 'Tell your friends',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: '',
                  onTap: () {},
                ),
                _buildSettingItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  subtitle: '',
                  onTap: () {},
                ),
                16.height,
              ],
            ),
            screenContext: context,
          )
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: bmPrimaryColor, size: 24),
      title: Text(title,
          style: boldTextStyle(
              size: 16,
              color: appStore.isDarkModeOn ? white : bmSpecialColorDark)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: secondaryTextStyle(size: 12))
          : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: bmPrimaryColor),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

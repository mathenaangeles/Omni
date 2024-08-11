import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.primary,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Image.asset('assets/logo.png', height: kToolbarHeight * 0.8),
      ),
      leadingWidth: 100,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
          style: TextButton.styleFrom(
            backgroundColor:
                currentRoute == '/' ? Colors.white.withOpacity(0.06) : null,
          ),
          child: const Text('Home'),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/assistant');
          },
          style: TextButton.styleFrom(
            backgroundColor: currentRoute == '/assistant'
                ? Colors.white.withOpacity(0.06)
                : null,
          ),
          child: const Text('Assistant'),
        ),
        const SizedBox(width: 10),
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Row(
                children: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundImage: AssetImage('assets/user.png'),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Logout'),
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Join Now'),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

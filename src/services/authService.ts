import {
  signInWithEmailAndPassword,
  signOut as fbSignOut,
  onAuthStateChanged,
} from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db, isFirebaseConfigured } from '../config/firebaseClient';
import type { UserProfile, UserRole } from '../types';
import { DEMO_USERS } from '../data/mockData';

export const authService = {
  /**
   * Signs in user either via Live Firebase Auth or Demo Role Selector
   */
  async signIn(email: string, password?: string): Promise<UserProfile> {
    if (isFirebaseConfigured && auth && db) {
      const userCredential = await signInWithEmailAndPassword(auth, email, password || 'Password@123');
      const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));
      if (userDoc.exists()) {
        return userDoc.data() as UserProfile;
      }
      throw new Error('User record not found in /users collection.');
    }

    // Mock Demo Mode fallback
    const matched = DEMO_USERS.find(u => u.email.toLowerCase() === email.toLowerCase());
    if (matched) {
      localStorage.setItem('drishtisetu_demo_user', JSON.stringify(matched));
      return matched;
    }
    // Default to Official if not matched
    return DEMO_USERS[0];
  },

  async signOut(): Promise<void> {
    if (isFirebaseConfigured && auth) {
      await fbSignOut(auth);
    }
    localStorage.removeItem('drishtisetu_demo_user');
  },

  getCurrentUser(): UserProfile | null {
    const saved = localStorage.getItem('drishtisetu_demo_user');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        return DEMO_USERS[0];
      }
    }
    return DEMO_USERS[0]; // Default logged-in as DoSJE Official for instant demonstration
  },

  switchRole(role: UserRole): UserProfile {
    const user = DEMO_USERS.find(u => u.role === role) || DEMO_USERS[0];
    localStorage.setItem('drishtisetu_demo_user', JSON.stringify(user));
    return user;
  }
};
